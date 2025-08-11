'use client'

import { useState } from 'react'

type SecretResponse = {
  segredo?: string
  raw?: string
  error?: string
}

export default function HomePage() {
  const [loading, setLoading] = useState(false)
  const [resp, setResp] = useState<SecretResponse | null>(null)

  const fetchSecret = async () => {
    setLoading(true)
    setResp(null)
    try {
      const res = await fetch('/api/segredo', { cache: 'no-store' })
      const data = await res.json()
      setResp(data)
    } catch (e: any) {
      setResp({ error: e?.message || 'Unknown error' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="card">
      <h1>🏰 Fortaleza dos Segredos – Explorer</h1>
      <p>
        This page calls <span className="code">/api/segredo</span>, which fetches the internal
        fortress URL defined in <span className="code">INTERNAL_FORTRESS_URL</span>.
      </p>

      <button className="btn" onClick={fetchSecret} disabled={loading}>
        {loading ? 'Buscando…' : 'Buscar Segredo'}
      </button>

      {resp && (
        <div className="card">
          {resp.error && <p className="status err">Erro: {resp.error}</p>}
          {!resp.error && (resp.segredo || resp.raw) && (
            <>
              {resp.segredo && (
                <p className="status ok">
                  <strong>segredo:</strong> <span className="code">{resp.segredo}</span>
                </p>
              )}
              {resp.raw && (
                <p className="status ok">
                  <strong>raw:</strong> <span className="code">{resp.raw}</span>
                </p>
              )}
            </>
          )}
          {!resp.error && !resp.segredo && !resp.raw && (
            <p className="status warn">Sem conteúdo retornado.</p>
          )}
        </div>
      )}
    </main>
  )
}