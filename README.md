# example_project

## Tools used in this project
* [Poetry](https://towardsdatascience.com/how-to-effortlessly-publish-your-python-package-to-pypi-using-poetry-44b305362f9f): Dependency management - [article](https://towardsdatascience.com/how-to-effortlessly-publish-your-python-package-to-pypi-using-poetry-44b305362f9f)
* [hydra](https://hydra.cc/): Manage configuration files - [article](https://towardsdatascience.com/introduction-to-hydra-cc-a-powerful-framework-to-configure-your-data-science-projects-ed65713a53c6)
* [pre-commit plugins](https://pre-commit.com/): Automate code reviewing formatting  - [article](https://towardsdatascience.com/4-pre-commit-plugins-to-automate-code-reviewing-and-formatting-in-python-c80c6d2e9f5?sk=2388804fb174d667ee5b680be22b8b1f)
* [DVC](https://dvc.org/): Data version control - [article](https://towardsdatascience.com/introduction-to-dvc-data-version-control-tool-for-machine-learning-projects-7cb49c229fe0)
* [pdoc](https://github.com/pdoc3/pdoc): Automatically create an API documentation for your project

## Project structure
```bash
.
├───.buildkite                              # Code to run on buildkite platform
│   ├───hooks                               # buildkite pre-command
│   ├───plugins                             # plugins for multiple customers, regions, sites
│   │   ├───get-environments-definition
│   │   │   └───hooks
│   │   └───get-python-comm                 # plugins for common python packages
│   │       └───hooks
│   └───scripts                             # scripts to check the difference between projects
├───api
│   └───migrations                          # scripts for API
├───batch
│   └───batch_linear_regression_scheduler   # script for batch scheduler - processor - writer
│       ├───.buildkite
│       │   └───scripts
│       └───terraform
│           ├───backend                     # backend infrastructure for terraform
│           ├───templates                   # user-data: install ssm, Inspector, and ECS config
│           └───vars                        # variables for each region
├───config
│   ├───model                               # config for each model
│   └───process                             # config for each process
├───dist
├───docs                                    # DOCUMENTATION
├───http_server                             # Http_server for inferencing
│   └───.buildkite
│       └───scripts
├───models                                  # models output 
├───notebooks                               # notebook for inference
├───src
│   └───__pycache__
└───tests
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
