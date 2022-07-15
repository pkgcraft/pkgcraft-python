import pickle

import pytest

from pkgcraft.error import PkgcraftError


class TestPkgcraftError:

    def test_new(self):
        with pytest.raises(PkgcraftError, match='error message'):
            raise PkgcraftError('error message')

    def test_no_c_error(self):
        with pytest.raises(RuntimeError, match='no error message'):
            raise PkgcraftError

    def test_pickle(self):
        e1 = PkgcraftError('error message')
        e2 = pickle.loads(pickle.dumps(e1))
        with pytest.raises(PkgcraftError, match='error message'):
            raise e2
