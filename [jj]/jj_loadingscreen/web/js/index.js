document.addEventListener("DOMContentLoaded", () => {
  const introTag = document.getElementById("intro");
  const audioTag = document.getElementById("background-audio");

  introTag.volume = 0.4;
  introTag.loop = true;

  audioTag.volume = 0.5; 
  audioTag.muted = false; 

  document.addEventListener("keydown", (event) => {
    if (event.code === "Space") {
      if (introTag.paused) introTag.play();
      introTag.muted = !introTag.muted;
      audioTag.muted = !audioTag.muted;
    } else if (event.code === "ArrowUp") {
      if (introTag.volume + 0.1 <= 1.0) introTag.volume += 0.1;
      if (audioTag.volume + 0.1 <= 1.0) audioTag.volume += 0.1;
    } else if (event.code === "ArrowDown") {
      if (introTag.volume - 0.1 >= 0.0) introTag.volume -= 0.1;
      if (audioTag.volume - 0.1 >= 0.0) audioTag.volume -= 0.1;
    }
  });
});
