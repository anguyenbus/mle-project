# example_project

## Tools used in this project
* [Poetry](https://towardsdatascience.com/how-to-effortlessly-publish-your-python-package-to-pypi-using-poetry-44b305362f9f): Dependency management - [article](https://towardsdatascience.com/how-to-effortlessly-publish-your-python-package-to-pypi-using-poetry-44b305362f9f)
* [pre-commit plugins](https://pre-commit.com/): Automate code reviewing formatting  - [article](https://towardsdatascience.com/4-pre-commit-plugins-to-automate-code-reviewing-and-formatting-in-python-c80c6d2e9f5?sk=2388804fb174d667ee5b680be22b8b1f)


## Project structure
```bash
.
│   batch.linear.regression.processor.Dockerfile
│   batch.linear.regression.scheduler.Dockerfile
│   batch.linear.regression.writer.Dockerfile   
│   Dockerfile
│   main.py
│   manage.py
│   README.md
│   requirements.txt
│   run.sh
│
├───.buildkite                                      # Code to run on buildkite platform
│   ├───hooks                                       
│   │       pre-command
│   │
│   ├───plugins                                     # plugins for multiple customers, regions, sites
│   │   ├───get-environments-definition
│   │   │   │   README.md
│   │   │   │
│   │   │   └───hooks
│   │   │           environment
│   │   │
│   │   └───get-python-comm
│   │       └───hooks
│   │               environment
│   │
│   └───scripts
│           diff.sh
│           find-branch-point.sh
│
├───api
│   │   apps.py
│   │   urls.py
│   │   views.py
│   │
│   └───migrations
│           __init__.py
│
├───batch
│   │   requirements.txt
│   │   scheduler.py
│   │
│   └───batch_linear_regression_scheduler
│       │   scheduler.py
│       │   scheduler_conf.yml
│       │   task-definition-template.json
│       │
│       ├───.buildkite
│       │   │   pipeline-deploy.yml
│       │   │   pipeline-destroy.yml
│       │   │   pipeline.yml
│       │   │   README.md
│       │   │
│       │   └───scripts
│       │           generate-deploy-trigger-step.js
│       │           generate-deploy-trigger-step.py
│       │
│       └───terraform
│           │   cloudwatch_log_group.tf
│           │   data.tf
│           │   ecs_gpu.tf
│           │   kinesis.tf
│           │   Makefile
│           │   mysql.tf
│           │   outputs.tf
│           │   provider.tf
│           │   roles.tf
│           │   scheduler_ecs_task.tf
│           │   sns.tf
│           │   ssm.tf
│           │   variables.tf
│           │
│           ├───backend
│           │       development.backend
│           │       production.backend
│           │       staging.backend
│           │
│           ├───templates
│           │       user-data.sh
│           │
│           └───vars
│                   development-ap-southeast-2.tfvars
│                   development-us-east-1.tfvars
│
├───config
│   │   main.yaml
│   │
│   ├───model
│   │       model1.yaml
│   │       model2.yaml
│   │
│   └───process
│           process1.yaml
│           process2.yaml
│
├───docs
│       .gitkeep
│       img.png
│       mlsys.png
│
├───http_server
│   │   asgi.py
│   │   settings.py
│   │   urls.py
│   │   wsgi.py
│   │   __init__.py
│   │
│   └───.buildkite
│       │   pipeline-deploy.yml
│       │   pipeline-destroy.yml
│       │   pipeline.yml
│       │   README.md
│       │   task-definiton-template.json
│       │
│       └───scripts
│               generate-deploy-trigger-step.js
│               generate-ecs-deploy-steps.js
│
├───models
│       .gitkeep
│
├───notebooks
│       .gitkeep
│
├───src
│       benchmark.py
│       simple_linear_regr.py
│       simple_linear_regr_utils.py
│       __init__.py
│
└───tests
        __init__.py
```

1. Installation
```bash
pip install mle-project
```

2. Test with python
```bash
from src import SimpleLinearRegression, evaluate, generate_data

X_train, y_train, X_test, y_test = generate_data()
model = SimpleLinearRegression()
model.fit(X_train, y_train)
predicted = model.predict(X_test)
evaluate(model, X_test, y_test, predicted)

```
