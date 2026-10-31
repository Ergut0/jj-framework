import { createOptions } from "./createOptions.js";

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;
const eye = document.querySelector(".target-dot");

window.addEventListener("message", (event) => {
  optionsWrapper.innerHTML = "";

  switch (event.data.event) {
    case "visible": {
      body.style.visibility = event.data.state ? "visible" : "hidden";
      if (!event.data.state) stopConnectionLoop();
      return eye.classList.remove("eye-hover");
    }

    case "leftTarget": {
      eye.classList.remove("eye-hover");
      stopConnectionLoop();
      return;
    }

    case "setTarget": {
      eye.classList.add("eye-hover");

      const hasOptions = event.data.options && Object.keys(event.data.options).length > 0;
      const hasZones = event.data.zones && event.data.zones.length > 0;

      if (hasOptions || hasZones) {
        if (event.data.options) {
          for (const type in event.data.options) {
            event.data.options[type].forEach((data, id) => {
              createOptions(type, data, id + 1);
            });
          }
        }

        if (event.data.zones) {
          for (let i = 0; i < event.data.zones.length; i++) {
            event.data.zones[i].forEach((data, id) => {
              createOptions("zones", data, id + 1, i + 1);
            });
          }
        }
        startConnectionLoop();
      } else {
        stopConnectionLoop();
      }
    }
  }
});

const svgLayer = document.getElementById("connection-layer");
let animationFrameId;

function startConnectionLoop() {
  if (animationFrameId) cancelAnimationFrame(animationFrameId);

  setupPaths();

  function loop() {
    updateLinePositions();
    animationFrameId = requestAnimationFrame(loop);
  }
  loop();
}

function stopConnectionLoop() {
  if (animationFrameId) cancelAnimationFrame(animationFrameId);
  svgLayer.innerHTML = '';
}

function setupPaths() {
  svgLayer.innerHTML = '';
  const options = document.querySelectorAll(".option-container");

  options.forEach(() => {
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.classList.add("connection-path");
    svgLayer.appendChild(path);
  });
}

function updateLinePositions() {
  const eyeRect = eye.getBoundingClientRect();
  const eyeX = eyeRect.left + eyeRect.width / 2;
  const eyeY = eyeRect.top + eyeRect.height / 2;

  const options = document.querySelectorAll(".option-container");
  const paths = svgLayer.querySelectorAll(".connection-path");

  options.forEach((opt, index) => {
    if (!paths[index]) return;

    const rect = opt.getBoundingClientRect();
    const optX = rect.left;
    const optY = rect.top + rect.height / 2;

    const cp1x = eyeX + 40;
    const cp1y = eyeY;
    const cp2x = optX - 40;
    const cp2y = optY;

    const d = `M ${eyeX} ${eyeY} C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${optX + 2} ${optY}`;
    paths[index].setAttribute("d", d);
  });
}
