Clone environment definition repo.

Can specify a branch or default to main branch

## Use main branch usage

```
    plugins:
      - ./.buildkite/plugins/get-environments-definition: ~
```

## Use another branch usage

```
    plugins:
      - ./.buildkite/plugins/get-environments-definition:
          branch: mycustombranch
```
