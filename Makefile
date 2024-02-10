update:
	@# pull:
	chezmoi update

	@# apply:
	chezmoi apply
	git log --oneline ...origin/main

	git --no-pager diff -w --exit-code --stat -p origin/main || make commit_and_push

update_short:
	@# pull:
	@chezmoi update > /dev/null

	@# apply:
	@chezmoi apply

	@git --no-pager diff -w --quiet --exit-code origin/main || echo "HAS_DIFF"

commit_and_push:
	@# ask user
	@echo "Press enter to commit and push:"
	@echo "PWD is $(PWD)"
	@sh -c 'read ok'

	@# push:
	git add --update
	git commit -m 'update' || true
	git push origin HEAD
	@echo "Pushed :)"
