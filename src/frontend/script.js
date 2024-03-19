document.addEventListener('DOMContentLoaded', () => {
    fetchRandomWord();
});

function fetchRandomWord() {
    fetch('https://your-api-gateway-url.execute-api.your-region.amazonaws.com/your-endpoint')
    .then(response => response.json())
    .then(data => {
        document.getElementById('randomWord').textContent = data.word;
    })
    .catch(error => console.error('Error fetching random word:', error));
}

function checkTranslation() {
    const userInput = document.getElementById('translationInput').value.trim().toLowerCase();
    const randomWord = document.getElementById('randomWord').textContent.trim().toLowerCase();

    if (userInput === randomWord) {
        document.getElementById('translationResult').textContent = 'Correct!';
    } else {
        document.getElementById('translationResult').textContent = 'Wrong! The translation is: ' + randomWord;
    }

    // Fetch a new random word after checking translation
    fetchRandomWord();
}
