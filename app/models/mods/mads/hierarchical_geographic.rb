module MODS
  module MADS
    class HierarchicalGeographic < ActiveFedora::Base
      property :label, predicate: MODS::RDFSVocabulary.label, multiple: false do |index|
         index.as :stored_searchable, :facetable
      end 
    end
  end
end