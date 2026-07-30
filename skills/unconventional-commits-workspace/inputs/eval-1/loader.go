package config

import (
	"encoding/json"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

// Load reads a config file and decodes it. It now supports both JSON and YAML,
// chosen by file extension. The previous version only handled JSON and had two
// nearly-identical decode blocks; those have been collapsed into decode().
func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}
	return decode(path, data)
}

func decode(path string, data []byte) (*Config, error) {
	var c Config
	switch ext(path) {
	case ".yaml", ".yml":
		return &c, yaml.Unmarshal(data, &c)
	case ".json":
		return &c, json.Unmarshal(data, &c)
	default:
		return nil, fmt.Errorf("unsupported config format: %s", path)
	}
}
