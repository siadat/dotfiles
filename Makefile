update:
	# pull:
	chezmoi update
	# apply:
	chezmoi apply
	# push:
	git add .
	git commit -m 'update'
	git push origin HEAD
