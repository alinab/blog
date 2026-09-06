{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE LambdaCase #-}
import           Control.Monad
import           Data.Maybe (fromMaybe, isJust)
import           Hakyll
import           Hakyll.Core.Compiler.Internal
import           Hakyll.Web.Tags (getTags)
import           Text.Pandoc.Options
import           KaTeXify
import qualified Text.Pandoc as Pandoc
import qualified Text.Pandoc.Walk as Pandoc
import qualified Data.Text as T

config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  }

main :: IO ()
main = hakyllWith config $ do -- Assets
  match "assets/**" $ do
    route idRoute
    compile copyFileCompiler

  match "CNAME" $ do
    route idRoute
    compile copyFileCompiler

  -- Templates
  match "templates/*" $ do
    compile templateCompiler

  -- Posts
  match ("posts/*.md" .||. "posts/*.lhs") $ do
    route $ setExtension "html"
    compile $
      pandocMathCompiler >>=
      loadAndApplyTemplate "templates/post.html" postCtx >>=
      saveSnapshot "content" >>=
      loadAndApplyTemplate "templates/default.html" postCtx >>=
      relativizeUrls

  -- For Notes
  match ("notes/*.md" .||. "notes/*.lhs") $ do
    route $ setExtension "html"
    compile $
      pandocMathCompiler >>=
      loadAndApplyTemplate "templates/note.html" noteCtx >>=
      saveSnapshot "content" >>=
      loadAndApplyTemplate "templates/default.html" noteCtx >>=
      relativizeUrls

  {-
  -- Posts
  match "code/*" $ do
    route $ setExtension "html"
    compile $ do
      ext <- getUnderlyingExtension
      compileGist "c" >>=
      loadAndApplyTemplate "templates/gist.html" defaultContext
  -}

  -- Archive
  create ["archive.html"] $ do
    route idRoute
    let archiveCtx =
          field "posts" (\_ -> postList recentFirst) <> constField "title" "bits and pieces — index" <> defaultContext
    compile $
      makeItem "" >>=
      loadAndApplyTemplate "templates/archive.html" archiveCtx >>=
      loadAndApplyTemplate "templates/default.html" archiveCtx >>=
      relativizeUrls

  -- Notes index
  create ["notes.html"] $ do
    route idRoute
    let notesIndexCtx =
          field "notes" (\_ -> noteList recentFirst) <> constField "title" "notes — index" <> defaultContext
    compile $
      makeItem "" >>=
      loadAndApplyTemplate "templates/notes.html" notesIndexCtx >>=
      loadAndApplyTemplate "templates/default.html" notesIndexCtx >>=
      relativizeUrls

  -- Splash page
  match "index.html" $ do
    route idRoute
    compile $ getResourceBody >>= relativizeUrls

  -- RSS and Atom
  create ["atom.xml"] $ renderFeed renderAtom
  create ["rss.xml"] $ renderFeedFpl renderRss

  -- CV
  -- match "cv/*" $ do
  --   route idRoute
  --   compile copyFileCompiler

postCtx :: Context String
postCtx = mconcat
  [ dateField "date" "%Y-%m-%d"
  , listFieldWith "tags" (field "tag" (return . itemBody)) $ \item -> do
      let identifier = itemIdentifier item
      meta <- getMetadata identifier
      let tags = fromMaybe ["post"] $ lookupStringList "tags" meta
      return $ map (Item identifier) tags
  , field "renderedTitle" $ \item -> do
      metadata <- getMetadata (itemIdentifier item)
      let str = fromMaybe "untitled" (lookupString "title" metadata)
      compilerUnsafeIO $ Pandoc.runIOorExplode $ do
        strWithParagraph <- Pandoc.readMarkdown Pandoc.def (T.pack str) >>= Pandoc.writeHtml5String Pandoc.def
        -- remove <p> and </p>
        return (T.unpack (T.reverse (T.drop (T.length "</p>") (T.reverse (T.drop (T.length "<p>") strWithParagraph)))))
  , defaultContext
  ]

postList :: ([Item String] -> Compiler [Item String]) -> Compiler String
postList sortFilter = do
  posts <- filterM isPublished =<< sortFilter =<< loadAll "posts/*"
  itemTpl <- loadBody "templates/post-item.html"
  list <- applyTemplateList itemTpl postCtx posts
  return list

noteCtx :: Context String
noteCtx = mconcat
  [ dateField "date" "%Y-%m-%d"
  , listFieldWith "tags" (field "tag" (return . itemBody)) $ \item -> do
      let identifier = itemIdentifier item
      meta <- getMetadata identifier
      let tags = fromMaybe ["note"] $ lookupStringList "tags" meta
      return $ map (Item identifier) tags
  , field "renderedTitle" $ \item -> do
      metadata <- getMetadata (itemIdentifier item)
      let str = fromMaybe "untitled" (lookupString "title" metadata)
      compilerUnsafeIO $ Pandoc.runIOorExplode $ do
        strWithParagraph <- Pandoc.readMarkdown Pandoc.def (T.pack str) >>= Pandoc.writeHtml5String Pandoc.def
        -- remove <p> and </p>
        return (T.unpack (T.reverse (T.drop (T.length "</p>") (T.reverse (T.drop (T.length "<p>") strWithParagraph)))))
  , defaultContext
  ]

noteList :: ([Item String] -> Compiler [Item String]) -> Compiler String
noteList sortFilter = do
  notes <- filterM isPublished =<< sortFilter =<< loadAll "notes/*"
  itemTpl <- loadBody "templates/note-item.html"
  list <- applyTemplateList itemTpl noteCtx notes
  return list

isPublished :: (MonadMetadata m, MonadFail m) => Item a -> m Bool
isPublished (itemIdentifier -> ident) = do
  liveM <- getMetadataField ident "live"
  case liveM of
    Nothing -> return False
    Just "false" -> return False
    Just "true" -> return True
    Just s -> fail ("invalid `live' metadata value: " ++ s)

isTagFpl :: (MonadMetadata m, MonadFail m) => Item a -> m Bool
isTagFpl (itemIdentifier -> ident) = elem "fpl" <$> getTags ident

renderFeed
  :: (FeedConfiguration -> Context String -> [Item String] -> Compiler (Item String))
  -> Rules ()
renderFeed f = do
  route idRoute
  let feedCtx = postCtx <> bodyField "description"
  compile $ do
    posts <- fmap (take 10) . recentFirst =<< filterM isPublished =<< loadAllSnapshots "posts/*" "content"
    f feedConf feedCtx posts

renderFeedFpl
  :: (FeedConfiguration -> Context String -> [Item String] -> Compiler (Item String))
  -> Rules ()
renderFeedFpl f = do
  route idRoute
  let feedCtx = postCtx <> bodyField "description"
  compile $ do
    posts <- fmap (take 20) . recentFirst
      =<< filterM isTagFpl
      =<< filterM isPublished
      =<< loadAllSnapshots "posts/*" "content"
    f feedConf feedCtx posts


feedConf :: FeedConfiguration
feedConf = FeedConfiguration
  { feedTitle       = "Alina's blog."
  , feedDescription = "types and bits"
  , feedAuthorName  = "Alina Banerjee"
  , feedAuthorEmail = "alina@blue-indus.in"
  , feedRoot        = "https://www.blue-indus.in"
  }

writerOpts :: Bool -> WriterOptions
writerOpts sidenotes = defaultHakyllWriterOptions
  { writerTableOfContents = True
  , writerExtensions =
      extensionsFromList mathExtensions <> writerExtensions defaultHakyllWriterOptions
  , writerHTMLMathMethod = KaTeX ""
  , writerReferenceLocation = if sidenotes then EndOfBlock else EndOfDocument
  }
  where
    mathExtensions =
      [Ext_tex_math_dollars, Ext_tex_math_double_backslash, Ext_latex_macros]

pandocMathCompiler :: Compiler (Item String)
pandocMathCompiler = do
  i <- getUnderlying
  katex <- getMetadataField i "katex"
  let katexTransform = if isJust katex then unsafeCompiler . kaTeXifyIO else return
  -- See <https://frasertweedale.github.io/blog-fp/posts/2020-12-10-hakyll-section-links.html>
  let sectionLinkTransform :: Monad m => Pandoc.Pandoc -> m Pandoc.Pandoc
      sectionLinkTransform = return . Pandoc.walk f where
        f (Pandoc.Header n attr@(idAttr, _, _) inlines) | n > 1 =
          let link = Pandoc.Link ("", ["section-link"], []) [Pandoc.Str "#"] ("#" <> idAttr, "")
          in Pandoc.Header n attr (inlines <> [Pandoc.Space, link])
        f x = x
  -- Open real links (not same-page "#..." anchors) in a new tab.
  let newTabLinkTransform :: Monad m => Pandoc.Pandoc -> m Pandoc.Pandoc
      newTabLinkTransform = return . Pandoc.walk f where
        f (Pandoc.Link (ident, classes, kvs) inlines target@(url, _))
          | not ("#" `T.isPrefixOf` url) =
              Pandoc.Link (ident, classes, kvs ++ [("target", "_blank"), ("rel", "noopener noreferrer")]) inlines target
        f x = x
  sidenotes <- maybe False (== "true") <$> getMetadataField i "sidenotes"
  pandocCompilerWithTransformM defaultHakyllReaderOptions (writerOpts sidenotes) (sectionLinkTransform >=> newTabLinkTransform >=> katexTransform)
