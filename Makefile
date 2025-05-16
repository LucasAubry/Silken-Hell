all:
	rm -rf game.love game
	zip -r game.zip *
	mv game.zip game.love
	echo boobies | npx love.js game.love game -c
	cp index.html game/
	python3 -m http.server --directory game
	xdg-open localhost:8000
