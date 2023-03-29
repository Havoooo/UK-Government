unless Rails.env.production?
  namespace :diagrams do
    desc "Generate model diagram"
    task :model, [:start_model] => :environment do |_, args|
      puts "Generating model diagram for #{args[:start_model]}"
      # note - eager load forces all models to be loaded for us
      Rails.application.eager_load!
      DiagramGenerator::ModelDiagram.new(args[:start_model], {through: true}).generate
    end
  end
end