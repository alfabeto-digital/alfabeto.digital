console.log('Script cargado');
document.addEventListener('DOMContentLoaded', function() {
    // Configurar fecha objetivo: 3 de marzo de 2026
    const targetDate = new Date('2026-03-03T00:00:00').getTime();
    const timerElements = {
        days: document.getElementById('days'),
        hours: document.getElementById('hours'),
        minutes: document.getElementById('minutes'),
        seconds: document.getElementById('seconds')
    };

    function updateTimer() {
        const now = new Date().getTime();
        const distance = targetDate - now;

        if (distance < 0) {
            clearInterval(timerInterval);
            document.querySelector('.timer').innerHTML = "<div class='expired'>¡Tiempo cumplido!</div>";
            return;
        }

        const days = Math.floor(distance / (1000 * 60 * 60 * 24));
        const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((distance % (1000 * 60)) / 1000);

        timerElements.days.textContent = days.toString().padStart(2, '0');
        timerElements.hours.textContent = hours.toString().padStart(2, '0');
        timerElements.minutes.textContent = minutes.toString().padStart(2, '0');
        timerElements.seconds.textContent = seconds.toString().padStart(2, '0');
    }

    // Verificar que los elementos existen antes de iniciar el timer
    if (timerElements.days && timerElements.hours && timerElements.minutes && timerElements.seconds) {
        const timerInterval = setInterval(updateTimer, 1000);
        updateTimer(); // Ejecutar inmediatamente
    } else {
        console.error('No se encontraron todos los elementos del timer');
    }
});