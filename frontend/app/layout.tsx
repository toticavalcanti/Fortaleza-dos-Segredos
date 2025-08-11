import '../styles/globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Fortaleza dos Segredos – Explorer',
  description: 'Explorer client (App Router) – RBAC, SA, NetworkPolicy, SecurityContext, Secrets.'
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>
        <div className="container">{children}</div>
      </body>
    </html>
  )
}