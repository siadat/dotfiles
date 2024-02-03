update:
	# pull:
	chezmoi update
	# apply:
	chezmoi apply
	git log --oneline ...origin/main

	git --no-pager diff --exit-code --stat -p origin/main || make commit_and_push

commit_and_push:
	# ask user
	@echo "Press enter to commit and push:"
	@echo "PWD is $(PWD)"
	@sh -c 'read ok'
	# push:
	git add --update
	git commit -m 'update' || true
	git push origin HEAD
	@echo "Pushed :)"
