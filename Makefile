GIT_COMMIT          := $(shell git describe --dirty=-unsupported --always --tags || echo pre-commit)
PROJECT_NAME        ?= 
AWS_LAMBDA_VERSION  ?= 
AWS_LAMBDA_RELEASE  ?= $(AWS_LAMBDA_VERSION)
AWS_LAMBDA_ZIP      ?= $(PROJECT_NAME)-lambda-$(AWS_LAMBDA_RELEASE).zip
AWS_PROFILE         ?=
AWS_S3_BUCKET       ?=  
AWS_ENV				?= 
AWS_S3_KEY          ?= lambda/$(PROJECT_NAME)-$(AWS_LAMBDA_RELEASE)-$(AWS_ENV)
AWS_STACK_NAME      ?= $(PROJECT_NAME)-stack-$(AWS_ENV)

.PHONY: venv
venv:
	pip3 install virtualenv; virtualenv venv

.PHONY: depend
depend:
	pip3 install -r requirements.txt

.PHONY: package
package:
	mkdir package; pip3 install -r requirements.txt -t package
	cd package; zip -r ../$(AWS_LAMBDA_ZIP) ../handler.py . ; cd ..

.PHONY: clean
clean:
	rm -rf $(AWS_LAMBDA_ZIP) venv package __pycache__

.PHONY: aws-publish
aws-publish:
	aws s3api put-object --bucket $(AWS_S3_BUCKET) --key $(AWS_S3_KEY) --body $(AWS_LAMBDA_ZIP) --profile $(AWS_PROFILE)

.PHONY: aws-deploy
aws-deploy:
	aws cloudformation create-stack --stack-name $(AWS_STACK_NAME) --template-body file://aws/cloudformation.json \
	--profile $(AWS_PROFILE) \
	--parameters file://aws/parameters-$(AWS_ENV).json

.PHONY: aws-undeploy
aws-undeploy:
	aws cloudformation delete-stack --stack-name $(AWS_STACK_NAME) --profile $(AWS_PROFILE)