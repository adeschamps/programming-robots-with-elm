.PHONY: robot upload

help: ## Prints a help guide
	@echo "Available tasks:"
	@grep -E '^[\%a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dependencies: ## Download dependencies
	yarn

robot: ## Compile robot's Elm code to JavaScript
	yarn elm make src/Sorter.elm --output=robot.js

upload: robot ## Compile code and copy to robot
	scp robot.js main.js ev3:
