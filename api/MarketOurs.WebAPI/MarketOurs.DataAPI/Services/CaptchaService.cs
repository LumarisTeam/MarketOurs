using MarketOurs.DataAPI.Configs;
using MarketOurs.DataAPI.Exceptions;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using StackExchange.Redis;

namespace MarketOurs.DataAPI.Services;

public interface ICaptchaService
{
    Task<CaptchaChallengeDto> GenerateChallengeAsync();
    Task<string?> VerifyChallengeAsync(string token, int x);
    Task<bool> ValidateCaptchaTokenAsync(string captchaToken);
}

public class CaptchaChallengeDto
{
    public string Token { get; set; } = string.Empty;
    public string BackgroundImage { get; set; } = string.Empty;
    public string PuzzleImage { get; set; } = string.Empty;
    public int PuzzleWidth { get; set; }
    public int PuzzleHeight { get; set; }
    public int PuzzleY { get; set; }
}

public class CaptchaService : ICaptchaService
{
    private readonly IConnectionMultiplexer? _redis;
    private readonly ILogger<CaptchaService> _logger;
    private readonly List<Image<Rgba32>> _sourceImages = [];
    private readonly string _imagesDir;
    private static readonly object _initLock = new();
    private bool _initialized;

    private const int BgWidth = 300;
    private const int BgHeight = 160;
    private const int PuzzleWidth = 50;
    private const int PuzzleHeight = 50;
    private const int MinX = 20;
    private const int MaxX = 230;
    private const int MinY = 10;
    private const int MaxY = 100;
    private const int Tolerance = 5;
    private const int ChallengeTtlMinutes = 5;
    private const int CaptchaTokenTtlMinutes = 5;

    private static readonly PngEncoder PngEncoder = new();

    public CaptchaService(
        IEnumerable<IConnectionMultiplexer> redisEnumerable,
        IHostEnvironment hostEnvironment,
        ILogger<CaptchaService> logger)
    {
        _redis = redisEnumerable.FirstOrDefault();
        _logger = logger;
        _imagesDir = Path.Combine(hostEnvironment.ContentRootPath, "wwwroot", "captcha-images");
    }

    private void EnsureInitialized()
    {
        if (_initialized) return;
        lock (_initLock)
        {
            if (_initialized) return;
            LoadImages();
            _initialized = true;
        }
    }

    private void LoadImages()
    {
        if (!Directory.Exists(_imagesDir))
        {
            _logger.LogInformation("Captcha images directory not found: {Dir}, will use generated images", _imagesDir);
            return;
        }

        var files = Directory.GetFiles(_imagesDir, "*.*")
            .Where(f => f.EndsWith(".png", StringComparison.OrdinalIgnoreCase) ||
                        f.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase) ||
                        f.EndsWith(".jpeg", StringComparison.OrdinalIgnoreCase) ||
                        f.EndsWith(".webp", StringComparison.OrdinalIgnoreCase))
            .ToList();

        foreach (var file in files)
        {
            try
            {
                var img = Image.Load<Rgba32>(file);
                img.Mutate(ctx => ctx.Resize(BgWidth, BgHeight));
                _sourceImages.Add(img);
                _logger.LogInformation("Loaded captcha image: {File}", Path.GetFileName(file));
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to load captcha image: {File}", file);
            }
        }

        _logger.LogInformation("Loaded {Count} captcha images from {Dir}", _sourceImages.Count, _imagesDir);
    }

    public async Task<CaptchaChallengeDto> GenerateChallengeAsync()
    {
        if (_redis == null)
            throw new BusinessException(ErrorCode.CacheOperationFailed, "Redis service unavailable");

        EnsureInitialized();

        var random = new Random();
        var puzzleX = random.Next(MinX, MaxX);
        var puzzleY = random.Next(MinY, MaxY);

        using var sourceImage = GetSourceImage(random);
        var bgBase64 = GenerateBackgroundImage(sourceImage, puzzleX, puzzleY);
        var puzzleBase64 = GeneratePuzzlePiece(sourceImage, puzzleX, puzzleY);

        var token = Guid.NewGuid().ToString("N");
        var db = _redis.GetDatabase();
        await db.StringSetAsync(
            CacheKeys.CaptchaChallenge(token),
            $"{puzzleX}:{puzzleY}",
            TimeSpan.FromMinutes(ChallengeTtlMinutes));

        return new CaptchaChallengeDto
        {
            Token = token,
            BackgroundImage = bgBase64,
            PuzzleImage = puzzleBase64,
            PuzzleWidth = PuzzleWidth,
            PuzzleHeight = PuzzleHeight,
            PuzzleY = puzzleY
        };
    }

    public async Task<string?> VerifyChallengeAsync(string token, int x)
    {
        if (_redis == null)
            throw new BusinessException(ErrorCode.CacheOperationFailed, "Redis service unavailable");

        var db = _redis.GetDatabase();
        var key = CacheKeys.CaptchaChallenge(token);
        var value = await db.StringGetAsync(key);

        if (!value.HasValue)
            return null;

        var parts = value.ToString().Split(':');
        if (parts.Length != 2 || !int.TryParse(parts[0], out var expectedX))
            return null;

        if (Math.Abs(expectedX - x) > Tolerance)
            return null;

        await db.KeyDeleteAsync(key);

        var captchaToken = Guid.NewGuid().ToString("N");
        await db.StringSetAsync(
            CacheKeys.CaptchaToken(captchaToken),
            "1",
            TimeSpan.FromMinutes(CaptchaTokenTtlMinutes));

        return captchaToken;
    }

    public async Task<bool> ValidateCaptchaTokenAsync(string captchaToken)
    {
        if (_redis == null) return true;

        var db = _redis.GetDatabase();
        var key = CacheKeys.CaptchaToken(captchaToken);
        var exists = await db.KeyExistsAsync(key);
        if (!exists) return false;

        await db.KeyDeleteAsync(key);
        return true;
    }

    private Image<Rgba32> GetSourceImage(Random random)
    {
        if (_sourceImages.Count > 0)
        {
            var idx = random.Next(_sourceImages.Count);
            return _sourceImages[idx].Clone();
        }

        return GenerateSourceImage(random);
    }

    private static string GenerateBackgroundImage(Image<Rgba32> source, int cutoutX, int cutoutY)
    {
        using var bg = source.Clone();

        for (var y = cutoutY; y < cutoutY + PuzzleHeight && y < BgHeight; y++)
        {
            for (var x = cutoutX; x < cutoutX + PuzzleWidth && x < BgWidth; x++)
            {
                var pixel = bg[x, y];
                bg[x, y] = new Rgba32(
                    (byte)(pixel.R / 3),
                    (byte)(pixel.G / 3),
                    (byte)(pixel.B / 3),
                    220);
            }
        }

        var borderColor = new Rgba32(255, 255, 255, 180);
        for (var x = cutoutX; x < cutoutX + PuzzleWidth && x < BgWidth; x++)
        {
            if (cutoutY < BgHeight) bg[x, cutoutY] = borderColor;
            if (cutoutY + PuzzleHeight - 1 < BgHeight) bg[x, cutoutY + PuzzleHeight - 1] = borderColor;
        }
        for (var y = cutoutY; y < cutoutY + PuzzleHeight && y < BgHeight; y++)
        {
            if (cutoutX < BgWidth) bg[cutoutX, y] = borderColor;
            if (cutoutX + PuzzleWidth - 1 < BgWidth) bg[cutoutX + PuzzleWidth - 1, y] = borderColor;
        }

        using var ms = new MemoryStream();
        bg.Save(ms, PngEncoder);
        return Convert.ToBase64String(ms.ToArray());
    }

    private static string GeneratePuzzlePiece(Image<Rgba32> source, int cutoutX, int cutoutY)
    {
        var pw = PuzzleWidth;
        var ph = PuzzleHeight;
        using var piece = new Image<Rgba32>(pw, ph);

        for (var y = 0; y < ph; y++)
        {
            for (var x = 0; x < pw; x++)
            {
                var sx = cutoutX + x;
                var sy = cutoutY + y;

                if (sx < BgWidth && sy < BgHeight)
                {
                    piece[x, y] = source[sx, sy];
                }
                else
                {
                    piece[x, y] = new Rgba32(200, 200, 200);
                }
            }
        }

        using var ms = new MemoryStream();
        piece.Save(ms, PngEncoder);
        return Convert.ToBase64String(ms.ToArray());
    }

    private static Image<Rgba32> GenerateSourceImage(Random rng)
    {
        var image = new Image<Rgba32>(BgWidth, BgHeight);
        var style = rng.Next(5);

        if (style == 0)
            GenerateSkyGradient(image, rng);
        else if (style == 1)
            GenerateGeometricLandscape(image, rng);
        else if (style == 2)
            GenerateAbstractCircles(image, rng);
        else if (style == 3)
            GenerateWavePattern(image, rng);
        else
            GenerateGridPattern(image, rng);

        return image;
    }

    private static void GenerateSkyGradient(Image<Rgba32> image, Random rng)
    {
        var topR = (byte)rng.Next(40, 120);
        var topG = (byte)rng.Next(60, 180);
        var topB = (byte)rng.Next(150, 255);

        var botR = (byte)rng.Next(200, 255);
        var botG = (byte)rng.Next(150, 220);
        var botB = (byte)rng.Next(80, 180);

        var sunColor = new Rgba32(255, (byte)rng.Next(200, 240), (byte)rng.Next(50, 150), 180);

        for (var y = 0; y < BgHeight; y++)
        {
            var t = (float)y / BgHeight;
            for (var x = 0; x < BgWidth; x++)
            {
                var r = (byte)(topR + (botR - topR) * t);
                var g = (byte)(topG + (botG - topG) * t);
                var b = (byte)(topB + (botB - topB) * t);
                image[x, y] = new Rgba32(r, g, b);
            }
        }

        var sunX = rng.Next(60, 240);
        var sunY = rng.Next(30, 90);
        var sunR = rng.Next(25, 50);
        for (var y = 0; y < BgHeight; y++)
        {
            for (var x = 0; x < BgWidth; x++)
            {
                var dx = x - sunX;
                var dy = y - sunY;
                var dist = Math.Sqrt(dx * dx + dy * dy);
                if (dist < sunR)
                {
                    var alpha = (byte)(180 * (1 - dist / sunR));
                    var pixel = image[x, y];
                    image[x, y] = new Rgba32(
                        (byte)Math.Min(255, pixel.R + sunColor.R * alpha / 255),
                        (byte)Math.Min(255, pixel.G + sunColor.G * alpha / 255),
                        (byte)Math.Min(255, pixel.B + sunColor.B * alpha / 255));
                }
            }
        }

        AddClouds(image, rng, 8);
    }

    private static void GenerateGeometricLandscape(Image<Rgba32> image, Random rng)
    {
        var skyR = (byte)rng.Next(80, 180);
        var skyG = (byte)rng.Next(120, 200);
        var skyB = (byte)rng.Next(180, 255);

        for (var y = 0; y < BgHeight; y++)
        {
            var t = (float)y / BgHeight;
            for (var x = 0; x < BgWidth; x++)
            {
                if (y < BgHeight * 0.55)
                {
                    image[x, y] = new Rgba32(
                        (byte)(skyR - t * 40),
                        (byte)(skyG - t * 20),
                        (byte)(skyB - t * 30));
                }
                else
                {
                    var groundT = (float)(y - BgHeight * 0.55) / (BgHeight * 0.45);
                    image[x, y] = new Rgba32(
                        (byte)(60 + groundT * 80),
                        (byte)(120 + groundT * 50),
                        (byte)(40 + groundT * 30));
                }
            }
        }

        AddMountainSilhouette(image, rng);
        AddClouds(image, rng, 5);
    }

    private static void AddMountainSilhouette(Image<Rgba32> image, Random rng)
    {
        var mountainColor = new Rgba32(
            (byte)rng.Next(30, 80),
            (byte)rng.Next(80, 140),
            (byte)rng.Next(30, 70));

        var peakCount = rng.Next(2, 5);
        for (var p = 0; p < peakCount; p++)
        {
            var peakX = rng.Next(30, BgWidth - 30);
            var peakY = rng.Next(40, 80);
            var width = rng.Next(80, 200);

            for (var y = peakY; y < BgHeight; y++)
            {
                for (var x = Math.Max(0, peakX - width / 2); x < Math.Min(BgWidth, peakX + width / 2); x++)
                {
                    var dx = Math.Abs(x - peakX) / (width / 2.0);
                    var mountainY = peakY + (BgHeight - peakY) * dx;
                    if (y >= mountainY)
                    {
                        var pixel = image[x, y];
                        image[x, y] = new Rgba32(
                            (byte)((pixel.R + mountainColor.R) / 2),
                            (byte)((pixel.G + mountainColor.G) / 2),
                            (byte)((pixel.B + mountainColor.B) / 2));
                    }
                }
            }
        }
    }

    private static void GenerateAbstractCircles(Image<Rgba32> image, Random rng)
    {
        var bgColor = new Rgba32(
            (byte)rng.Next(20, 60),
            (byte)rng.Next(20, 60),
            (byte)rng.Next(30, 80));

        for (var y = 0; y < BgHeight; y++)
        for (var x = 0; x < BgWidth; x++)
            image[x, y] = bgColor;

        var circleCount = rng.Next(8, 15);
        for (var i = 0; i < circleCount; i++)
        {
            var cx = rng.Next(0, BgWidth);
            var cy = rng.Next(0, BgHeight);
            var cr = rng.Next(20, 80);
            var color = new Rgba32(
                (byte)rng.Next(80, 255),
                (byte)rng.Next(80, 255),
                (byte)rng.Next(80, 255),
                (byte)rng.Next(40, 120));

            for (var y = Math.Max(0, cy - cr); y < Math.Min(BgHeight, cy + cr); y++)
            {
                for (var x = Math.Max(0, cx - cr); x < Math.Min(BgWidth, cx + cr); x++)
                {
                    var dx = x - cx;
                    var dy = y - cy;
                    if (dx * dx + dy * dy < cr * cr)
                    {
                        var pixel = image[x, y];
                        var alpha = color.A / 255f;
                        image[x, y] = new Rgba32(
                            (byte)(pixel.R * (1 - alpha) + color.R * alpha),
                            (byte)(pixel.G * (1 - alpha) + color.G * alpha),
                            (byte)(pixel.B * (1 - alpha) + color.B * alpha));
                    }
                }
            }
        }
    }

    private static void GenerateWavePattern(Image<Rgba32> image, Random rng)
    {
        var color1 = new Rgba32(
            (byte)rng.Next(30, 100),
            (byte)rng.Next(80, 180),
            (byte)rng.Next(120, 220));
        var color2 = new Rgba32(
            (byte)rng.Next(100, 200),
            (byte)rng.Next(120, 200),
            (byte)rng.Next(40, 120));

        var freq = rng.NextDouble() * 0.02 + 0.01;
        var amp = rng.Next(20, 50);

        for (var y = 0; y < BgHeight; y++)
        {
            for (var x = 0; x < BgWidth; x++)
            {
                var wave = Math.Sin(x * freq + y * 0.05) * amp + Math.Sin(y * freq * 2) * amp * 0.5;
                var t = (y + wave - BgHeight / 2.0) / BgHeight + 0.5;
                t = Math.Clamp(t, 0, 1);

                image[x, y] = new Rgba32(
                    (byte)(color1.R * (1 - t) + color2.R * t),
                    (byte)(color1.G * (1 - t) + color2.G * t),
                    (byte)(color1.B * (1 - t) + color2.B * t));
            }
        }
    }

    private static void GenerateGridPattern(Image<Rgba32> image, Random rng)
    {
        var bgColor = new Rgba32(
            (byte)rng.Next(200, 240),
            (byte)rng.Next(200, 240),
            (byte)rng.Next(200, 240));

        for (var y = 0; y < BgHeight; y++)
        for (var x = 0; x < BgWidth; x++)
            image[x, y] = bgColor;

        var cellSize = rng.Next(15, 30);
        for (var gy = 0; gy < BgHeight; gy += cellSize)
        {
            for (var gx = 0; gx < BgWidth; gx += cellSize)
            {
                var r = (byte)rng.Next(80, 200);
                var g = (byte)rng.Next(80, 200);
                var b = (byte)rng.Next(80, 200);
                var cellColor = new Rgba32(r, g, b, (byte)rng.Next(60, 180));

                for (var y = gy; y < Math.Min(gy + cellSize, BgHeight); y++)
                {
                    for (var x = gx; x < Math.Min(gx + cellSize, BgWidth); x++)
                    {
                        var pixel = image[x, y];
                        var alpha = cellColor.A / 255f;
                        image[x, y] = new Rgba32(
                            (byte)(pixel.R * (1 - alpha) + cellColor.R * alpha),
                            (byte)(pixel.G * (1 - alpha) + cellColor.G * alpha),
                            (byte)(pixel.B * (1 - alpha) + cellColor.B * alpha));
                    }
                }
            }
        }
    }

    private static void AddClouds(Image<Rgba32> image, Random rng, int count)
    {
        var cloudColor = new Rgba32(255, 255, 255, 60);
        for (var i = 0; i < count; i++)
        {
            var cx = rng.Next(0, BgWidth);
            var cy = rng.Next(10, 60);
            var cw = rng.Next(30, 80);
            var ch = rng.Next(10, 25);

            for (var y = Math.Max(0, cy - ch / 2); y < Math.Min(BgHeight, cy + ch / 2); y++)
            {
                for (var x = Math.Max(0, cx - cw / 2); x < Math.Min(BgWidth, cx + cw / 2); x++)
                {
                    var dx = (x - cx) / (cw / 2.0);
                    var dy = (y - cy) / (ch / 2.0);
                    if (dx * dx + dy * dy < 1)
                    {
                        var pixel = image[x, y];
                        image[x, y] = new Rgba32(
                            (byte)Math.Min(255, pixel.R + cloudColor.R * cloudColor.A / 255),
                            (byte)Math.Min(255, pixel.G + cloudColor.G * cloudColor.A / 255),
                            (byte)Math.Min(255, pixel.B + cloudColor.B * cloudColor.A / 255));
                    }
                }
            }
        }
    }
}
