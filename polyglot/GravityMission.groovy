import groovy.transform.Immutable
@Immutable class GravityMission { String slug; String title; String metric; BigDecimal target; String completion; boolean complete(Map<String,BigDecimal> telemetry){telemetry.getOrDefault(metric,0G)>=target} }
class MissionCatalog {
    static List<GravityMission> build(Closure specification){def catalog=[];def builder=new Expando();builder.mission={Map values->catalog<<new GravityMission(values.slug,values.title,values.metric,values.target as BigDecimal,values.completion)};specification.delegate=builder;specification.resolveStrategy=Closure.DELEGATE_FIRST;specification();catalog.asImmutable()}
}
def missions=MissionCatalog.build{
    mission slug:'dock-six',title:'Return six misplaced objects',metric:'docked_objects',target:6,completion:'The office recognizes the floor again.'
    mission slug:'sideways',title:'Maintain sideways weather',metric:'sideways_weather',target:12,completion:'The walls accepted their new responsibilities.'
}
