.PHONY: release clean

release:
	@mkdir -p ./dist
	@rm -f ./dist/xvoldrv00-release.zip
	@cd ../src && zip -q -r ../.development/dist/xvoldrv00-release.zip . \
		-x '.env' '.env.*' '*/.env' '*/.env.*' 'temp/cache/*'
	@cd ../src && zip -q ../.development/dist/xvoldrv00-release.zip .env.example
	@echo "Release created: ./dist/xvoldrv00-release.zip"
	scp ./dist/xvoldrv00-release.zip xvoldrv00@eva.fit.vutbr.cz:WWW/
	@echo unzip the .zip
	@echo then run "chmod -R o=rX,g= ~/WWW"
	ssh xvoldrv00@eva.fit.vutbr.cz

clean:
	@rm -rf ./dist
