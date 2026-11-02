import dragSound from '../assets/sounds/drag.wav';

let dragAudio: HTMLAudioElement | undefined;

export const playDragSound = () => {
  dragAudio ??= new Audio(dragSound);
  dragAudio.currentTime = 0;
  void dragAudio.play().catch(() => undefined);
};
