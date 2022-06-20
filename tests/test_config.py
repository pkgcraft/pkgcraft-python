from pkgcraft import Config


class TestConfig:

    def test_load(self):
        config = Config()
        assert config
