{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    decPlugin = lib.mkOption {
      type =
        let
          thisType = lib.types.lazyAttrsOf (
            lib.types.oneOf [
              (lib.mkOptionType {
                name = "null";
                check = x: x == null;
                emptyValue.value = null;
              })
              lib.types.package
              lib.types.lines
              thisType
            ]
          );
        in
        thisType;
    };

  };
  config = {
    plugins.start = lib.pipe config.decPlugin [
      (lib.mapAttrsToListRecursiveCond (_: as: (!lib.isDerivation as)) (
        path: v:
        if v == null then
          v
        else
          "install -D '${
            if (lib.isDerivation v || lib.isStorePath v) then
              v
            else
              pkgs.writeText ("mnw-" + builtins.concatStringsSep "-" path) v
          }' \"$out/${
            builtins.concatStringsSep "/" (
              map (
                x:
                assert lib.assertMsg ((builtins.match ".*/.*" x) == null) ''
                  mnw-declarative-plugin: path "${x}" contains '/' which is not allowed
                  instead of "${builtins.concatStringsSep "\".\"" path}" use "${
                    builtins.concatStringsSep "\".\"" (map (x: builtins.replaceStrings [ "/" ] [ "\".\"" ] x) path)
                  }" instead
                '';
                x
              ) path
            )
          }\""
      ))
      (builtins.filter (x: x != null))
      lib.concatLines
      (pkgs.runCommand "mnw-declarative-plugin" { })
      lib.singleton
    ];
  };
}
