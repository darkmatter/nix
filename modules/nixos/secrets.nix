{ agenix }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.darkmatter.secrets;
  secrets = {
    openai-api-key = ../../secrets/openai-api-key.age;
  };
in
{
  imports = [
    agenix.nixosModules.default
  ];

  options.darkmatter.secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Darkmatter shared agenix secrets.";
    };

    names = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames secrets));
      default = lib.attrNames secrets;
      description = "Darkmatter secret names to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = lib.genAttrs cfg.names (name: {
      file = secrets.${name};
    });
  };
}
