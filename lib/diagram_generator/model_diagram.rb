module DiagramGenerator
  ClassNode = Struct.new(:name, :stereotype) do
    def to_uml
      <<~UML
        class #{name} #{stereotype || ''}
      UML
    end
  end

  NormalRelationship = Struct.new(:macro, :name)
  ThroughRelationship = Struct.new(:macro, :name, :original)

  AssociationKey = Struct.new(:from, :to)
  class Associations
    def initialize(key)
      @key = key
      # a link can represent several relationships
      @normal_relationships = []
      @through_relationships = []
    end

    def add(relationship)
      @normal_relationships << relationship
    end

    def add_through(relationship)
      @through_relationships << relationship
    end

    def normal_description
      relationship_count_summary(@normal_relationships)
    end

    def through_description
      "(through) #{relationship_count_summary(@through_relationships)}"
    end

    def to_uml
      case [@normal_relationships.length, @through_relationships.length]
      in [0, 0]
        raise "logic error - no relationships"
      in [1.., 0]
        <<~UML
          #{@key.from} --> #{@key.to} : "#{normal_description}"
        UML
      in [0, 1..]
        <<~UML
          #{@key.from} ..> #{@key.to} : "#{through_description}"
        UML
      in [1.., 1..]
        <<~UML
          #{@key.from} --> #{@key.to} : "#{normal_description}"
          #{@key.from} ..> #{@key.to} : "#{through_description}"
        UML
      else
        raise "logic error - invalid relationship counts #{[@normal_relationships.length, @through_relationships.length]}"
      end
    end

  private

    def relationship_count_summary(relationships)
      counts = Hash.new(0)
      relationships.each { |rel| counts[rel.macro] += 1 }
      counts.map { |macro, count| count == 1 ? macro : "#{macro} x #{count}" }.join(",")
    end
  end

  # Don't store inheritance as a relationship because it's quite different and specific
  InheritanceLink = Struct.new(:from, :to) do
    def to_uml
      <<~UML
        #{from} <|-- #{to} #line:blue;line.bold
      UML
    end
  end

  class ModelDiagram
    def initialize(base_name, options)
      @options = options

      unless Object.const_defined?(base_name)
        raise "Unknown class #{base_name}"
      end

      @base_name = base_name
      base_class = Object.const_get(base_name)
      unless base_class < ActiveRecord::Base
        raise "#{base_class.name} does not descent from ActiveRecord::Base"
      end

      if base_class.subclasses.empty?
        puts "Note #{base_class.name} has no subclasses - maybe run `Rails.application.eager_load!` first?"
      end
      @class_layers = []
      @extra_classes = []
      @associations = Hash.new { |h, key| h[key] = Associations.new(key) }
      @inheritance_links = [] # order doesn't matter
      @node_names = Set.new
      add_class(base_class, nil, 0)
    end

    def generate
      $stdout.print <<~UML
        @startuml
        allowmixing
        hide empty members
      UML

      $stdout.puts "rectangle #{@base_name}Family {"
      @class_layers.each do |layer|
        layer.each do |plantuml_class|
          $stdout.print plantuml_class.to_uml
        end
      end
      $stdout.puts "}"

      # $stdout.puts "together {"
      @extra_classes.each do |plantuml_class|
        $stdout.print plantuml_class.to_uml
      end
      # $stdout.puts "}"

      @inheritance_links.each do |link|
        $stdout.print link.to_uml
      end
      @associations.each_value do |link|
        $stdout.print link.to_uml
      end

      $stdout.print "@enduml"
    end

  private

    def add_class(klass, parent, depth)
      (@class_layers[depth] ||= []) << ClassNode.new(klass.name)
      @node_names << klass.name
      unless parent.nil?
        @inheritance_links << InheritanceLink.new(parent.name, klass.name)
      end
      klass.subclasses.each do |subclass|
        add_class(subclass, klass, depth + 1)
      end

      associations = klass.reflect_on_all_associations
      superclass_associations = klass.superclass.reflect_on_all_associations
      my_associations = associations.reject { |a| superclass_associations.include? a }
      my_associations.each do |a|
        process_association klass.name, a, associations
      end
    end

    def add_extra_class(class_name)
      unless @node_names.include? class_name
        @extra_classes << ClassNode.new(class_name)
        @node_names << class_name
      end
    end

    def add_model_link(new_link)
      if @inheritance_links.any? { |link| link.from == new_link.from && link.to == new_link.to }
        puts "ignoring duplicate ? but should we merge?"
      end
    end

    def process_association(class_name, assoc, all_assoc)
      #  some of this is from railroady, but kept a lot simpler
      macro = assoc.macro.to_s
      through = assoc.options.include?(:through)

      if through
        return unless @options[:through]

        through_name = assoc.options[:through]
        through_assoc = all_assoc.find { |a| a.name == through_name }
        unless through_assoc
          warn "Can't find through association from #{class_name} to #{assoc.name} through #{through_name}"
          return
        end
        # puts "adding through assoc #{class_name} -> #{through_assoc.macro.to_s} #{through_assoc.class_name} name #{through_assoc.name} -> #{macro} #{assoc.class_name} name #{assoc.name}"
        unless @node_names.include? assoc.class_name
          add_extra_class(assoc.class_name)
        end
        @associations[AssociationKey.new(through_assoc.class_name, assoc.class_name)].add_through(ThroughRelationship.new(macro, assoc.name, class_name))
      else
        # puts "adding assoc from #{class_name}  #{macro} to #{assoc.class_name} name #{assoc.name}"
        unless @node_names.include? assoc.class_name
          add_extra_class(assoc.class_name)
        end
        @associations[AssociationKey.new(class_name, assoc.class_name)].add(NormalRelationship.new(macro, assoc.name))
      end
    end
  end
end
