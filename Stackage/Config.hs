{-# LANGUAGE CPP #-}
module Stackage.Config where

import           Control.Monad              (when)
import           Control.Monad.Trans.Writer (execWriter, tell)
import qualified Data.Map                   as Map
import           Data.Set                   (fromList, singleton)
import           Distribution.Text          (simpleParse)
import           Stackage.Types

-- | Packages which are shipped with GHC but are not included in the
-- Haskell Platform list of core packages.
defaultExtraCore :: GhcMajorVersion -> Set PackageName
defaultExtraCore _ = fromList $ map PackageName $ words
    "binary Win32"

-- | Test suites which are expected to fail for some reason. The test suite
-- will still be run and logs kept, but a failure will not indicate an
-- error in our package combination.
defaultExpectedFailures :: GhcMajorVersion
                        -> Set PackageName
defaultExpectedFailures ghcVer = execWriter $ do
      -- Requires an old version of WAI and Warp for tests
    add "HTTP"

      -- text and setenv have recursive dependencies in their tests, which
      -- cabal can't (yet) handle
    add "text"
    add "setenv"

      -- The version of GLUT included with the HP does not generate
      -- documentation correctly.
    add "GLUT"

      -- https://github.com/bos/statistics/issues/42
    add "statistics"

      -- https://github.com/kazu-yamamoto/simple-sendfile/pull/10
    add "simple-sendfile"

      -- http://hackage.haskell.org/trac/hackage/ticket/954
    add "diagrams"

      -- https://github.com/fpco/stackage/issues/24
    add "unix-time"

      -- With transformers 0.3, it doesn't provide any modules
    add "transformers-compat"

      -- Tests require shell script and are incompatible with sandboxed package
      -- databases
    add "HTF"

      -- https://github.com/simonmar/monad-par/issues/28
    add "monad-par"

      -- Unfortunately network failures seem to happen haphazardly
    add "network"

      -- https://github.com/ekmett/hyphenation/issues/1
    add "hyphenation"

      -- Test suite takes too long to run on some systems
    add "punycode"

      -- http://hub.darcs.net/stepcut/happstack/issue/1
    add "happstack-server"

      -- Requires a Facebook app.
    add "fb"

      -- https://github.com/tibbe/hashable/issues/64
    add "hashable"

      -- https://github.com/vincenthz/language-java/issues/10
    add "language-java"

    add "threads"
    add "crypto-conduit"
    add "pandoc"
    add "language-ecmascript"
    add "hspec"
    add "alex"

      -- https://github.com/basvandijk/concurrent-extra/issues/
    add "concurrent-extra"

      -- https://github.com/rrnewton/haskell-lockfree-queue/issues/7
    add "abstract-deque"

      -- https://github.com/skogsbaer/xmlgen/issues/2
    add "xmlgen"

      -- Something very strange going on with the test suite, I can't figure
      -- out how to fix it
    add "bson"

      -- Requires a locally running PostgreSQL server with appropriate users
    add "postgresql-simple"

      -- https://github.com/IreneKnapp/direct-sqlite/issues/32
    add "direct-sqlite"

      -- Missing files
    add "websockets"

      -- Some kind of Cabal bug when trying to run tests
    add "thyme"

    when (ghcVer < GhcMajorVersion 7 6) $ do
        -- https://github.com/haskell-suite/haskell-names/issues/39
        add "haskell-names"
  where
    add = tell . singleton . PackageName

-- | List of packages for our stable Hackage. All dependencies will be
-- included as well. Please indicate who will be maintaining the package
-- via comments.
defaultStablePackages :: GhcMajorVersion -> Map PackageName (VersionRange, Maintainer)
defaultStablePackages ghcVer = unPackageMap $ execWriter $ do
    mapM_ (add "michael@snoyman.com") $ words =<<
        [ "yesod yesod-newsfeed yesod-sitemap yesod-static yesod-test yesod-bin"
        , "markdown filesystem-conduit mime-mail-ses"
        , "persistent persistent-template persistent-sqlite"
        , "network-conduit-tls yackage warp-tls keter"
        , "shakespeare-text process-conduit stm-conduit"
        , "classy-prelude-yesod yesod-fay yesod-eventsource wai-websockets"
        , "random-shuffle safe-failure hackage-proxy"
        ]

    mapM_ (add "FP Complete <michael@fpcomplete.com>") $ words =<<
        [ "web-fpco th-expand-syns configurator compdata smtLib unification-fd"
        , "fixed-list indents language-c pretty-class"
        , "aws yesod-auth-oauth csv-conduit cassava"
        , "async shelly thyme"
        , "hxt hxt-relaxng dimensional"
        , "cairo diagrams-cairo"
        , "persistent-mongoDB"
        ]
    when (ghcVer < GhcMajorVersion 7 6) $ do
        addRange "FP Complete <michael@fpcomplete.com>" "hxt" "<= 9.3.0.1"
        addRange "FP Complete <michael@fpcomplete.com>" "shelly" "<= 1.0"

        -- https://github.com/fpco/stackage/issues/122
        addRange "FP Complete <michael@fpcomplete.com>" "shake" "< 0.10.7"
    when (ghcVer >= GhcMajorVersion 7 6) $ do
        add "FP Complete <michael@fpcomplete.com>" "repa-devil"
    addRange "FP Complete <michael@fpcomplete.com>" "kure" "<= 2.4.10"

    mapM_ (add "Neil Mitchell") $ words
        "hlint hoogle shake derive"

    mapM_ (add "Alan Zimmerman") $ words
        "hjsmin language-javascript"

    mapM_ (add "Jasper Van der Jeugt") $ words
        "blaze-html blaze-markup stylish-haskell"

    mapM_ (add "Antoine Latter") $ words
        "uuid byteorder"

    mapM_ (add "Stefan Wehr <wehr@factisresearch.com>") $ words
        "HTF hscurses xmlgen stm-stats"

    mapM_ (add "Bart Massey <bart.massey+stackage@gmail.com>") $ words
        "parseargs"

    mapM_ (add "Vincent Hanquez") $ words =<<
        [ "asn1-data bytedump certificate cipher-aes cipher-rc4 connection"
        , "cprng-aes cpu crypto-pubkey-types crypto-random-api cryptocipher"
        , "cryptohash hit language-java libgit pem siphash socks tls"
        , "tls-debug tls-extra vhd"
        ]
    addRange "Vincent Hanquez" "language-java" "< 0.2.5"

#if !defined(mingw32_HOST_OS) && !defined(__MINGW32__)
    -- Does not compile on Windows
    mapM_ (add "Vincent Hanquez") $ words "udbus xenstore"
#endif

    mapM_ (add "Alberto G. Corona <agocorona@gmail.com>") $ words
         "RefSerialize TCache Workflow MFlow"

    mapM_ (add "Edward Kmett <ekmett@gmail.com>") $ words =<<
        [ "ad adjunctions bifunctors bound categories charset comonad comonad-transformers"
        , "comonads-fd comonad-extras compressed concurrent-supply constraints contravariant"
        , "distributive either eq free groupoids heaps hyphenation"
        , "integration intervals kan-extensions lca lens linear monadic-arrays machines"
        , "mtl profunctors profunctor-extras reducers reflection"
        , "representable-functors representable-tries"
        , "semigroups semigroupoids semigroupoid-extras speculation tagged void"
        , "graphs monad-products monad-st wl-pprint-extras wl-pprint-terminfo"
        , "numeric-extras parsers pointed prelude-extras recursion-schemes reducers"
        , "streams syb-extras vector-instances"
        ]

    mapM_ (add "Simon Hengel <sol@typeful.net>") $ words
        "hspec doctest base-compat"

    mapM_ (add "Brent Yorgey <byorgey@gmail.com>") $ words =<<
        [ "monoid-extras dual-tree vector-space-points active force-layout"
        , "diagrams diagrams-contrib diagrams-core diagrams-lib diagrams-svg"
        , "diagrams-postscript diagrams-builder diagrams-haddock haxr"
        , "BlogLiterately BlogLiterately-diagrams"
        ]

    mapM_ (add "Patrick Brisbin") $ words "gravatar"

    mapM_ (add "Felipe Lessa <felipe.lessa@gmail.com>") $ words
        "esqueleto fb fb-persistent yesod-fb yesod-auth-fb"

    mapM_ (add "Alexander Altman <alexanderaltman@me.com>") $ words
        "base-unicode-symbols containers-unicode-symbols"

    mapM_ (add "Ryan Newton <ryan.newton@alum.mit.edu>") $ words
        "accelerate"

    mapM_ (add "Dan Burton <danburton.email@gmail.com>") $ words =<<
        [ "basic-prelude composition io-memoize numbers rev-state runmemo"
        , "tardis"
        ]

    mapM_ (add "Daniel Díaz <dhelta.diaz@gmail.com>") $ words
        "HaTeX"

    mapM_ (add "Adam Bergmark <adam@edea.se>") $ words
        "fay fay-base"

    mapM_ (add "Boris Lykah <lykahb@gmail.com>") $ words
        "groundhog groundhog-th groundhog-sqlite groundhog-postgresql groundhog-mysql"

    -- https://github.com/fpco/stackage/issues/46
    addRange "Michael Snoyman" "QuickCheck" "< 2.6"

    -- https://github.com/fpco/stackage/issues/68
    addRange "Michael Snoyman" "criterion" "< 0.8"

    -- https://github.com/fpco/stackage/issues/72
    addRange "Michael Snoyman" "HaXml" "< 1.24"

    -- Due to binary package dep
    addRange "Michael Snoyman" "statistics" "< 0.10.4"

    -- https://github.com/fpco/stackage/issues/97
    addRange "Michael Snoyman" "tagsoup" "< 0.13"

    -- https://github.com/fpco/stackage/issues/107
    addRange "Michael Snoyman" "split" "< 0.2.2"

    -- https://github.com/fpco/stackage/issues/118
    addRange "Michael Snoyman" "pem" "< 0.2"

    -- https://github.com/fpco/stackage/issues/123
    addRange "Michael Snoyman" "cryptohash" "< 0.11"

    -- https://github.com/fpco/stackage/issues/124
    addRange "Michael Snoyman" "fclabels" "< 2.0"

    -- Newest hxt requires network 2.4 or newest
    addRange "Michael Snoyman" "hxt" "< 9.3.1"
    addRange "Michael Snoyman" "network" "< 2.4"

    -- https://github.com/fpco/stackage/issues/129
    addRange "Michael Snoyman" "comonad" "< 4"
    addRange "Michael Snoyman" "comonads-fd" "< 4"
    addRange "Michael Snoyman" "comonad-transformers" "< 4"
    addRange "Michael Snoyman" "free" "< 4"
    addRange "Michael Snoyman" "semigroupoids" "< 4"
    addRange "Michael Snoyman" "semigroupoid-extras" "< 4"
    addRange "Michael Snoyman" "eq" "< 4"
    addRange "Michael Snoyman" "pointed" "< 4"
    addRange "Michael Snoyman" "profunctors" "< 4"
    addRange "Michael Snoyman" "profunctor-extras" "< 4"
    addRange "Michael Snoyman" "groupoids" "< 4"
    addRange "Michael Snoyman" "bifunctors" "< 4"
    addRange "Michael Snoyman" "hashable-extras" "< 0.2"
    addRange "Michael Snoyman" "lens" "< 3.10"
    addRange "Michael Snoyman" "keys" "< 3.10"
    addRange "Michael Snoyman" "reducers" "< 3.10"
    addRange "Michael Snoyman" "compressed" "< 3.10"
    addRange "Michael Snoyman" "either" "< 4"

    addRange "Michael Snoyman" "hashable" "< 1.2"

    -- Requires binary 0.7
    addRange "FP Complete <michael@fpcomplete.com>" "bson" "< 0.2.3"

    -- unknown symbol `utf8_table4'
    addRange "Michael Snoyman" "regex-pcre-builtin" "< 0.94.4.6.8.31"
  where
    add maintainer package = addRange maintainer package "-any"
    addRange maintainer package range =
        case simpleParse range of
            Nothing -> error $ "Invalid range " ++ show range ++ " for " ++ package
            Just range' -> tell $ PackageMap $ Map.singleton (PackageName package) (range', Maintainer maintainer)
