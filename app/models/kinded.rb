module Kinded
  # Kinded models will have a 'kind' which will print out dds#{kind_name}
  # the default kind_name is the name of the class
  # kind_name should always be downcased, so to over this method
  # make sure to call super(your_new_kind_name)
  def kind(kind_name=nil)
    kind_name ||= self.class.name
    ['dds',kind_name.downcase].join('#')
  end
end
