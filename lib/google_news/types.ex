defmodule GoogleNews.Error do
  @type t :: %__MODULE__{message: String.t(), value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "google_news found an error: #{inspect(value)}"
  end

  def message(%{message: message}) do
    message
  end
end

defmodule GoogleNews.SubArticle do
  @type t :: %__MODULE__{
          title: binary,
          url: binary,
          publisher: binary
        }

  defstruct title: nil,
            url: nil,
            publisher: nil
end

defmodule GoogleNews.Entry do
  alias GoogleNews.SubArticle

  @type t :: %__MODULE__{
          author: binary,
          categories: [binary],
          duration: binary,
          enclosure: binary,
          id: binary,
          image: binary,
          link: binary,
          subtitle: binary,
          summary: binary,
          title: binary,
          updated: binary,
          sub_articles: [SubArticle.t()]
        }

  defstruct author: nil,
            categories: [],
            duration: nil,
            enclosure: nil,
            id: nil,
            image: nil,
            link: nil,
            subtitle: nil,
            summary: nil,
            title: nil,
            updated: nil,
            sub_articles: []
end

defmodule GoogleNews.FeedInfo do
  @type t :: %__MODULE__{
          author: binary,
          id: binary,
          image: binary,
          link: binary,
          language: binary,
          subtitle: binary,
          summary: binary,
          title: binary,
          updated: binary,
          url: binary
        }

  defstruct author: nil,
            id: nil,
            image: nil,
            link: nil,
            language: nil,
            subtitle: nil,
            summary: nil,
            title: nil,
            updated: nil,
            url: nil
end

defmodule GoogleNews.Feed do
  alias GoogleNews.{FeedInfo, Entry}

  @typedoc """
  Struct that contains Parsed RSS Feed information.
  """
  @type t :: %__MODULE__{
          feed: FeedInfo.t(),
          entries: [Entry.t()]
        }

  defstruct feed: %FeedInfo{},
            entries: []
end
