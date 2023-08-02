require "spec_helper"

RSpec.describe "Delegation name collisions" do
  it "raises when a name collides" do
    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        delegate :application_title, to: :header

        def application_title
          "redeclared"
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)

    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        def application_title
          "redeclared"
        end

        delegate :application_title, to: :header
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)
  end

  it "handles collision tracking when methods are prefixed" do
    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        delegate :application_title, to: :header, prefix: :awesome

        def awesome_application_title
          "redeclared"
        end
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)

    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        def awesome_application_title
          "redeclared"
        end

        delegate :application_title, to: :header, prefix: :awesome
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)

    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        def header_application_title
          "redeclared"
        end

        delegate :application_title, to: :header, prefix: true
      end
    end.to raise_error(PageEz::DuplicateElementDeclarationError)
  end

  it "does not raise when collisions do not occur" do
    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        delegate :application_title, to: :header, prefix: :awesome

        def application_title
          "different than prefixed"
        end
      end
    end.not_to raise_error

    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        def application_title
          "redeclared"
        end

        delegate :application_title, to: :header, prefix: :awesome
      end
    end.not_to raise_error

    expect do
      Class.new(PageEz::Page) do
        has_one :header do
          has_one :application_title, "h1"
        end

        def application_title
          "redeclared"
        end

        delegate :application_title, to: :header, prefix: true
      end
    end.not_to raise_error
  end

  it "raises exceptions from the underlying delegate logic from ActiveSupport" do
    expect do
      Class.new(PageEz::Page) do
        delegate :application_title
      end
    end.to raise_error(ArgumentError)

    expect do
      Class.new(PageEz::Page) do
        delegate :application_title, to: nil
      end
    end.to raise_error(ArgumentError)
  end
end
