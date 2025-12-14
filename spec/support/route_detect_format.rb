#
# Ce monkey-patch permet de détecter les usages des url helpers qui passent accidentellement
# une valeur excédentaire qui est interprétée comme le format, ce qui génère des URLs du genre :
# "/admin/organisations/4/planning/absences/new.2?duplicate_absence_id=1"
#
if Rails.env.test?
  # Il faut copier la méthode `handle_positional_args` depuis `action_dispatch/routing/route_set.rb:292`
  # puis ajouter le `raise` dans le block `args.each_with_index` comme ci-dessous.
  raise "Il faut recopier ce code quand on change de version de Rails" if Rails.version != "8.0.4"

  class ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper
    def handle_positional_args(controller_options, inner_options, args, result, path_params)
      if args.size > 0
        # take format into account
        if path_params.include?(:format)
          path_params_size = path_params.size - 1
        else
          path_params_size = path_params.size
        end

        if args.size < path_params_size
          path_params -= controller_options.keys
          path_params -= (result[:path_params] || {}).merge(result).keys
        else
          path_params = path_params.dup
        end
        inner_options.each_key do |key|
          path_params.delete(key)
        end

        args.each_with_index do |arg, index|
          param = path_params[index]
          raise "Can't implicitly pass #{arg.inspect} as format" if param == :format
          result[param] = arg if param
        end
      end

      result.merge!(inner_options)
    end
  end
end
