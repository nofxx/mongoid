require "spec_helper"

describe Mongoid::QueryCache do

  around do |spec|
    Mongoid::QueryCache.clear_cache
    Mongoid::QueryCache.cache { spec.run }
  end

  pending "when querying for a single document" do

    [ :first, :one, :last ].each do |method|

      before do
        Band.all.send(method)
      end

      pending "when query cache disable" do

        before do
          Mongoid::QueryCache.enabled = false
        end

        it "queries again" do
          expect_query(1) do
            Band.all.send(method)
          end
        end
      end

      pending "with same selector" do

        it "does not query again" do
          expect_no_queries do
            Band.all.send(method)
          end
        end
      end

      pending "with different selector" do

        it "queries again" do
          expect_query(1) do
            Band.where(id: 1).send(method)
          end
        end
      end
    end
  end

  pending "when querying in the same collection" do

    before do
      Band.all.to_a
    end

    pending "when query cache disable" do

      before do
        Mongoid::QueryCache.enabled = false
      end

      it "queries again" do
        expect_query(1) do
          Band.all.to_a
        end
      end
    end

    pending "with same selector" do

      it "does not query again" do
        expect_no_queries do
          Band.all.to_a
        end
      end

      pending "when querying only the first" do
        let(:game) { Game.create!(name: "2048") }

        before do
          game.ratings.where(:value.gt => 5).asc(:id).all.to_a
        end

        it "queries again" do
          expect_query(1) do
            game.ratings.where(:value.gt => 5).asc(:id).first
          end
        end
      end

      pending "limiting the result" do
        it "queries again" do
          expect_query(1) do
            Band.limit(2).all.to_a
          end
        end
      end

      pending "specifying a different skip value" do
        before do
          Band.limit(2).skip(1).all.to_a
        end

        it "queries again" do
          expect_query(1) do
            Band.limit(2).skip(3).all.to_a
          end
        end
      end
    end

    pending "with different selector" do

      it "queries again" do
        expect_query(1) do
          Band.where(id: 1).to_a
        end
      end
    end
  end

  pending "when querying in different collection" do

    before do
      Person.all.to_a
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  pending "when inserting a new document" do

    before do
      Band.all.to_a
      Band.create!
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  pending "when deleting all documents" do

    before do
      Band.create!
      Band.all.to_a
      Band.delete_all
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  pending "when destroying all documents" do

    before do
      Band.create!
      Band.all.to_a
      Band.destroy_all
    end

    it "queries again" do
      expect_query(1) do
        Band.all.to_a
      end
    end
  end

  pending "when querying a very large collection" do

    before do
      123.times { Band.create! }
    end

    it "returns the right number of records" do
      expect(Band.all.to_a.length).to eq(123)
    end

    it "#pluck returns the same count of objects" do
      expect(Band.pluck(:name).length).to eq(123)
    end

    pending "when loading all the documents" do

      before do
        Band.all.to_a
      end

      it "caches the complete result of the query" do
        expect_no_queries do
          expect(Band.all.to_a.length).to eq(123)
        end
      end

      it "returns the same count of objects when using #pluck" do
        expect(Band.pluck(:name).length).to eq(123)
      end
    end
  end

  pending "when inserting an index" do

    it "does not cache the query" do
      expect(Mongoid::QueryCache).to receive(:cache_table).never
      Band.collection.indexes.create(name: 1)
    end
  end
end

describe Mongoid::QueryCache::Middleware do

  let :middleware do
    Mongoid::QueryCache::Middleware.new(app)
  end

  pending "when not touching mongoid on the app" do

    let(:app) do
      ->(env) { @enabled = Mongoid::QueryCache.enabled?; [200, env, "app"] }
    end

    it "returns success" do
      code, _ = middleware.call({})
      expect(code).to eq(200)
    end

    it "enableds the query cache" do
      middleware.call({})
      expect(@enabled).to be true
    end
  end

  pending "when querying on the app" do

    let(:app) do
      ->(env) {
        Band.all.to_a
        [200, env, "app"]
      }
    end

    it "returns success" do
      code, _ = middleware.call({})
      expect(code).to eq(200)
    end

    it "cleans the query cache after reponds" do
      middleware.call({})
      expect(Mongoid::QueryCache.cache_table).to be_empty
    end
  end
end