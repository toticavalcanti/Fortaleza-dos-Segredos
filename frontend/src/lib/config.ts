/** Centralized server-side config loader */
export const getConfig = () => {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || ''
  const fortressUrl = process.env.INTERNAL_FORTRESS_URL || ''
  return { baseUrl, fortressUrl }
}