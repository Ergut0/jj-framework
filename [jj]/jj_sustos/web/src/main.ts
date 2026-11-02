import './styles.css';

const scream = document.querySelector<HTMLAudioElement>('#scream')!;
const images = document.querySelectorAll<HTMLImageElement>('.scare');

function stop() {
  images.forEach((image) => image.classList.remove('scare-active'));
  scream.pause();
  scream.currentTime = 0;
}

function start(kind: string, volume: number) {
  stop();
  document.getElementById(kind)?.classList.add('scare-active');
  scream.volume = volume;
  scream.play().catch(() => {});
}

window.addEventListener('message', ({ data }) => {
  if (data.action === 'start') start(data.kind, data.volume);
  else if (data.action === 'stop') stop();
});
