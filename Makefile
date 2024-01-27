update:
	# pull:
	chezmoi update
	# apply:
	chezmoi apply
	# push:
	git add --update
	git commit -m 'update' || true
	git diff origin HEAD
	@echo "Press enter to push:"
	@sh -c 'read ok'
	git push origin HEAD
