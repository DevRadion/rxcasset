# RXCAsset

XCAsset automation tool.

- References find and replace:

```bash
rxcasset -replace -project <absolute_project_path> -old <old_asset_name> -new <new_asset_name>
```

- Find all references without replacement:

```bash
rxcasset -replace -project <absolute_project_path> -old <old_asset_name> 
```

- Sync all asset files with asset names

```bash
rxcasset -sync -xcassets <absolute_xcassets_dir_path> 
```

> written in Zig using Neovim btw
