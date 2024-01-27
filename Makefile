update:
	chezmoi apply
	git add .
	git commit -m 'update'
	git push origin HEAD
