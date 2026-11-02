import { useEffect, useState } from 'react';

const dateFormat = new Intl.DateTimeFormat('es-ES', { timeZone: 'Europe/Madrid', day: '2-digit', month: '2-digit', year: 'numeric' });
const timeFormat = new Intl.DateTimeFormat('es-ES', { timeZone: 'Europe/Madrid', hour: '2-digit', minute: '2-digit', hour12: false });

const now = () => {
  const date = new Date();
  return `${dateFormat.format(date)} ${timeFormat.format(date)}`;
};

export function Clock() {
  const [text, setText] = useState(now);

  useEffect(() => {
    const timer = setInterval(() => setText(now()), 10000);
    return () => clearInterval(timer);
  }, []);

  return <span className="clock">{text}</span>;
}
