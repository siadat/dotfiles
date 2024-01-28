update:
	# pull:
	chezmoi update

	# apply:
	chezmoi apply
	git log --oneline ...origin/main
	git --no-pager diff --stat -p origin/main

	@echo "Press enter to commit and push:"
	@sh -c 'read ok'

	# push:
	git add --update
	git commit -m 'update' || true
	git push origin HEAD
