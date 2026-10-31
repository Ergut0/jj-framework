window.addEventListener("message", function (event) {
  if (event.data.action === "showDeathScreen") {
    showDeathScreen(event.data.seconds);
  } else if (event.data.action === "hideDeathScreen") {
    hideDeathScreen();
  }
});

function showDeathScreen(seconds) {
  let deathScreen = document.getElementById("deathScreen");

  if (!deathScreen) {
    deathScreen = document.createElement("div");
    deathScreen.classList.add("notification");
    deathScreen.setAttribute("id", "deathScreen");

    deathScreen.innerHTML = `
            <div class="notification-icon">
                <img src="https://img.icons8.com/ios-filled/50/ffffff/skull.png" alt="Icono de Muerte">
            </div>
            <div class="notification-content" id="notificationContent">
                <h2>¡ESTÁS HERIDO!</h2>
                <p>Te quedan <span class="highlight" id="secondsLeft">${seconds}</span> segundos restantes.</p>
            </div>
        `;

    document.body.appendChild(deathScreen);
  } else {
    const notificationContent = document.getElementById("notificationContent");
    const secondsLeftEl = document.getElementById("secondsLeft");

    if (seconds > 0) {
      if (secondsLeftEl) {
        secondsLeftEl.textContent = seconds;
      } else if (notificationContent) {
        notificationContent.innerHTML = `
                <h2>¡ESTÁS HERIDO!</h2>
                <p>Te quedan <span class="highlight" id="secondsLeft">${seconds}</span> segundos restantes.</p>
            `;
      } else {
        deathScreen.innerHTML = `
            <div class="notification-icon">
                <img src="https://img.icons8.com/ios-filled/50/ffffff/skull.png" alt="Icono de Muerte">
            </div>
            <div class="notification-content" id="notificationContent">
                <h2>¡ESTÁS HERIDO!</h2>
                <p>Te quedan <span class="highlight" id="secondsLeft">${seconds}</span> segundos restantes.</p>
            </div>
        `;
      }
    } else {
      if (notificationContent) {
        notificationContent.innerHTML = `
                <h2>¡ESTÁS INCOSCIENTE!</h2>
                <p>Mantén <span class="highlight">E</span> para ir al hospital.</p>
            `;
      } else {
        deathScreen.innerHTML = `
            <div class="notification-icon">
                <img src="https://img.icons8.com/ios-filled/50/ffffff/skull.png" alt="Icono de Muerte">
            </div>
            <div class="notification-content" id="notificationContent">
                <h2>¡ESTÁS INCOSCIENTE!</h2>
                <p>Mantén <span class="highlight">E</span> para ir al hospital.</p>
            </div>
        `;
      }
    }
  }
}

function hideDeathScreen() {
  let deathScreen = document.getElementById("deathScreen");
  if (deathScreen) {
    deathScreen.remove();
  }
}
