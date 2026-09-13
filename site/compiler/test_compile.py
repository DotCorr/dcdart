import unittest
from compile import compile_source
class InputValidation(unittest.TestCase):
    def test_directives_are_rejected(self):
        for source in ["import 'file:///etc/passwd';", "part '/tmp/input.json';", "export 'x';", "library x;"]:
            with self.assertRaisesRegex(ValueError,'single|one file'):compile_source(source)
    def test_size_and_type_are_rejected(self):
        for source in [None,123,'a'*32769,'𝒙'*9000]:
            with self.assertRaisesRegex(ValueError,'32 KiB'):compile_source(source)
if __name__=='__main__':unittest.main()
