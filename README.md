# Go Run Tmux

Send command to specific tmux panel and execute `go run`

## Usage

```vim
:lua require("gorun").open()

"or command
:GoRun
```

## Configuration

Config file should located at: `{workingDirectory}/.vscode/launch.json`. Format almost like [launch.json](https://github.com/golang/vscode-go/blob/master/docs/debugging.md#configuration)

### Mandatory fields:

- `name`: the name of your configuration as it appears in the drop-down in the Run view.
- `cwd`: absolute path to the working directory of the program
- `tmux_target`: which panel to execute. Format: `{sessionName}:{windownName}.{panelIndex}` or `{windownName}.{panelIndex}`

### Example

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "one",
      "cwd": "absolute_path_to_run"
      "tmux_target": "dev:console.2",
    },
    {
      "name": "two",
      "cwd": "absolute_path_to_run",
      "tmux_target": "dev:console.3",
    }
  ]
}
```
