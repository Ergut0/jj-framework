import { useEffect, useState } from 'react';

// Si la imagen no carga, se muestra la inicial del trabajo
export function JobLogo({ src, label, size }: { src?: string; label: string; size: number }) {
  const [failed, setFailed] = useState(false);

  useEffect(() => setFailed(false), [src]);

  return (
    <span className="job-logo" style={{ width: size, height: size, fontSize: size * 0.42 }}>
      {src && !failed ? <img src={src} alt="" onError={() => setFailed(true)} /> : label.charAt(0).toUpperCase()}
    </span>
  );
}
