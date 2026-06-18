import { useState, useEffect } from "react"

function useScrollPosition(_throttleMs?: number) {
  const [scrollY, setScrollY] = useState(0)
  const [isScrolled, setIsScrolled] = useState(false)

  useEffect(() => {
    let ticking = false

    function handleScroll() {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          const y = window.scrollY
          setScrollY(y)
          setIsScrolled(y > 10)
          ticking = false
        })
        ticking = true
      }
    }

    window.addEventListener("scroll", handleScroll, { passive: true })
    handleScroll()

    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  return { scrollY, isScrolled }
}

export { useScrollPosition }
