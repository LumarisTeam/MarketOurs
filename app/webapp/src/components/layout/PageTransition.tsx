import * as React from "react"
import { motion } from "motion/react"

interface PageTransitionProps {
  children: React.ReactNode
}

function PageTransition({ children }: PageTransitionProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{
        duration: 0.35,
        ease: [0.25, 0.1, 0.25, 1], // Apple's standard ease-out
      }}
    >
      {children}
    </motion.div>
  )
}

export { PageTransition }
