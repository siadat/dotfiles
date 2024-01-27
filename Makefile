update:
	# pull:
	chezmoi update
	# apply:
	chezmoi apply
	# push:
	git add --update
	git commit -m 'update' || true
	git --no-pager diff origin/main
	@echo "Press enter to push:"
	@sh -c 'read ok'
	git push origin HEAD
