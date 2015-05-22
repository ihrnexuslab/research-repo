class KarkinosFileEditForm < KarkinosGenericFilePresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions
  include AttributeHelper
  include NestedTitlePrincipals
  include NestedTitleUniforms
  include NestedSubjectTopics
  include NestedSubjectGeographics
  include NestedGenres
  include NestedLocationOfResources
  include NestedNamePrincipals
  include NestedNames
  include NestedNoteGroups
  include NestedParts
  include NestedSubjectTemporals
  include NestedSubjectTitles
  include NestedSubjectGeographicCodes
  include NestedSubjectHierarchicalGeographics
  include NestedCartographics
  include NestedSubjectOccupations
  include NestedSubjectGenres
  
  self.required_fields = [:title, :creator, :tag, :rights]  

end