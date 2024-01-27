update:
	# pull:
	chezmoi update
	# apply:
	chezmoi apply
	# push:
	git add --update
	git commit -m 'update'

	@echo "Press enter to push:"
	read -r
	git push origin HEAD
