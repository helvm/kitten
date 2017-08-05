{-|
Module      : Kitten.Token
Description : Tokens produced by the tokenizer
Copyright   : (c) Jon Purdy, 2016
License     : MIT
Maintainer  : evincarofautumn@gmail.com
Stability   : experimental
Portability : GHC
-}

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE OverloadedStrings #-}

module Kitten.Token
  ( Token(..)
  , float
  , fromLayout
  ) where

import Data.Ratio ((%))
import Data.Text (Text)
import Kitten.Base (Base(..))
import Kitten.Bits
import Kitten.Layoutness (Layoutness(..))
import Kitten.Name (Unqualified)
import Numeric
import Text.PrettyPrint.HughesPJClass (Pretty(..))
import Unsafe.Coerce (unsafeCoerce)
import qualified Data.Text as Text
import qualified Text.PrettyPrint as Pretty

data Token (l :: Layoutness) where

  -- | @about@
  About :: Token l

  -- | @<@ See note [Angle Brackets].
  AngleBegin :: Token l

  -- | @>@ See note [Angle Brackets].
  AngleEnd :: Token l

  -- | @->@
  Arrow :: Token l

  -- | @as@
  As :: Token l

  -- | @{@, @:@
  BlockBegin :: Token l

  -- | @}@
  BlockEnd :: Token l

  -- | @case@
  Case :: Token l

  -- | @'x'@
  Character :: !Char -> Token l

  -- | @:@
  Colon :: Token 'Layout

  -- | @,@
  Comma :: Token l

  -- | @define@
  Define :: Token l

  -- | @do@
  Do :: Token l

  -- | @...@
  Ellipsis :: Token l

  -- | @elif@
  Elif :: Token l

  -- | @else@
  Else :: Token l

  -- | See note [Float Literals].
  Float :: !Integer -> !Int -> !Int -> !FloatBits -> Token l

  -- | @(@
  GroupBegin :: Token l

  -- | @)@
  GroupEnd :: Token l

  -- | @if@
  If :: Token l

  -- | @_@
  Ignore :: Token l

  -- | @instance@
  Instance :: Token l

  -- | @1@, 0b1@, @0o1@, @0x1@, @1i64, @1u16@
  Integer :: !Integer -> !Base -> !IntegerBits -> Token l

  -- | @intrinsic@
  Intrinsic :: Token l

  -- | @jump@
  Jump :: Token l

  -- | @match@
  Match :: Token l

  -- | @+@
  Operator :: !Unqualified -> Token l

  -- | @permission@
  Permission :: Token l

  -- | @\@
  Reference :: Token l

  -- | @return@
  Return :: Token l

  -- | @synonym@
  Synonym :: Token l

  -- | @"..."@
  Text :: !Text -> Token l

  -- | @trait@
  Trait :: Token l

  -- | @type@
  Type :: Token l

  -- | @[@
  VectorBegin :: Token l

  -- | @]@
  VectorEnd :: Token l

  -- | @vocab@
  Vocab :: Token l

  -- | @::@
  VocabLookup :: Token l

  -- | @with@
  With :: Token l

  -- | @word@
  Word :: !Unqualified -> Token l

fromLayout :: Token l -> Maybe (Token 'Nonlayout)
fromLayout Colon = Nothing
fromLayout x = Just (unsafeCoerce x)

instance Eq (Token l) where
  About                   == About                   = True
  AngleBegin              == AngleBegin              = True
  AngleEnd                == AngleEnd                = True
  Arrow                   == Arrow                   = True
  As                      == As                      = True
  BlockBegin              == BlockBegin              = True
  BlockEnd                == BlockEnd                = True
  Case                    == Case                    = True
  Character a             == Character b             = a == b
  Colon                   == Colon                   = True
  Comma                   == Comma                   = True
  Define                  == Define                  = True
  Do                      == Do                      = True
  Ellipsis                == Ellipsis                = True
  Elif                    == Elif                    = True
  Else                    == Else                    = True
  -- See note [Float Literals].
  -- TODO: Incorporate bits in equality testing?
  Float a b c _bitsA      == Float d e f _bitsB      = (a, c - b) == (d, f - e)
  GroupBegin              == GroupBegin              = True
  GroupEnd                == GroupEnd                = True
  If                      == If                      = True
  Ignore                  == Ignore                  = True
  Instance                == Instance                = True
  -- Integer tokens are equal regardless of base.
  -- TODO: Incorporate bits/wrapping in equality testing?
  Integer a _baseA _bitsA == Integer b _baseB _bitsB = a == b
  Intrinsic               == Intrinsic               = True
  Jump                    == Jump                    = True
  Match                   == Match                   = True
  Operator a              == Operator b              = a == b
  Permission              == Permission              = True
  Reference               == Reference               = True
  Return                  == Return                  = True
  Synonym                 == Synonym                 = True
  Text a                  == Text b                  = a == b
  Trait                   == Trait                   = True
  Type                    == Type                    = True
  VectorBegin             == VectorBegin             = True
  VectorEnd               == VectorEnd               = True
  Vocab                   == Vocab                   = True
  VocabLookup             == VocabLookup             = True
  With                    == With                    = True
  Word a                  == Word b                  = a == b
  _                       == _                       = False

instance Pretty (Token l) where
  pPrint token = case token of
    About -> "about"
    AngleBegin -> "<"
    AngleEnd -> ">"
    Arrow -> "->"
    As -> "as"
    BlockBegin{} -> "{"
    BlockEnd -> "}"
    Case -> "case"
    Character c -> Pretty.quotes $ Pretty.char c
    Colon -> ":"
    Comma -> ","
    Define -> "define"
    Do -> "do"
    Ellipsis -> "..."
    Elif -> "elif"
    Else -> "else"
    Float a b c bits -> Pretty.hcat [Pretty.double $ float a b c, pPrint bits]
    GroupBegin -> "("
    GroupEnd -> ")"
    If -> "if"
    Ignore -> "_"
    Instance -> "instance"
    Integer value hint bits
      -> Pretty.text $ if value < 0 then '-' : shown else shown
      where
      shown = concat
        [prefix, showIntAtBase base (digits !!) (abs value) "", suffix]
      (base, prefix, digits) = case hint of
        Binary -> (2, "0b", "01")
        Octal -> (8, "0o", ['0'..'7'])
        Decimal -> (10, "", ['0'..'9'])
        Hexadecimal -> (16, "0x", ['0'..'9'] ++ ['A'..'F'])
      suffix = case bits of
        Signed32 -> ""
        _ -> Pretty.render $ pPrint bits
    Intrinsic -> "intrinsic"
    Jump -> "jump"
    Match -> "match"
    Operator name -> pPrint name
    Permission -> "permission"
    Reference -> "\\"
    Return -> "return"
    Synonym -> "synonym"
    Text t -> Pretty.doubleQuotes $ Pretty.text $ Text.unpack t
    Trait -> "trait"
    Type -> "type"
    VectorBegin -> "["
    VectorEnd -> "]"
    Vocab -> "vocab"
    VocabLookup -> "::"
    With -> "with"
    Word name -> pPrint name

-- Minor hack because Parsec requires 'Show'.
instance Show (Token l) where
  show = Pretty.render . pPrint

-- Note [Angle Brackets]:
--
-- Since we separate the passes of tokenization and parsing, we are faced with a
-- classic ambiguity between angle brackets as used in operator names such as
-- '>>' and '<+', and as used in type argument and parameter lists such as
-- 'vector<vector<T>>' and '<+E>'.
--
-- Our solution is to parse a less-than or greater-than character as an 'angle'
-- token if it was immediately followed by a symbol character in the input, with
-- no intervening whitespace. This is enough information for the parser to
-- disambiguate the intent:
--
--   • When parsing an expression, it joins a sequence of angle tokens and
--     an operator token into a single operator token.
--
--   • When parsing a signature, it treats them separately.
--
-- You may ask why we permit this silly ambiguity in the first place. Why not
-- merge the passes of tokenization and parsing, or use a different bracketing
-- character such as '[]' for type argument lists?
--
-- We separate tokenization and parsing for the sake of tool support: it's
-- simply easier to provide token-accurate source locations when we keep track
-- of source locations at the token level, and it's easier to provide a list of
-- tokens to external tools (e.g., for syntax highlighting) if we already have
-- such a list at hand.
--
-- The reason for the choice of bracketing character is for the sake of
-- compatibility with C++ tools. When setting a breakpoint in GDB, for example,
-- it's nice to be able to type:
--
--     break foo::bar<int>
--
-- And for this to refer to the Kitten definition 'foo::bar<int>' precisely,
-- rather than to some syntactic analogue such as 'foo.bar[int]'. The modest
-- increase in complexity of implementation is justified by fostering a better
-- experience for people.

-- Note [Float Literals]:
--
-- Floating-point literals are represented as a pair of an arbitrary-precision
-- integer significand and exponent, so that:
--
--     Float a b c
--
-- Denotes the floating point number (a × 10^(c - b)). This representation was
-- chosen to avoid loss of precision until the token is converted into a machine
-- floating-point format. The exponent is split into two parts to indicate which
-- part of the literal that exponent came from: the fractional part, or the
-- exponent in scientific notation.

float :: Fractional a => Integer -> Int -> Int -> a
float a b c = let
  e = c - b
  -- The intermediate rational step is necessary to preserve precision.
  shift = if e < 0 then 1 % 10 ^ negate e else 10 ^ e
  in fromRational $ (fromIntegral a :: Rational) * shift
