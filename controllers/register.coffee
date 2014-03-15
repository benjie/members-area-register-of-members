Controller = require 'members-area/app/controller'

defaultDetailsHtml = """
  <div class="companyName">
    <h4>So Make It Ltd.</h4>

    <p class="legal">Registered in England and Wales,<br>
    company number 08442741.</p>
  </div>

  <div class="address">
    <p>6 Irving Road</p>

    <p>Southampton</p>

    <p>SO16 4DZ</p>
  </div>

  <div class="contact">
    <p>Tel: +44 (0) 7773 679729</p>

    <p>Email: trustees@somakeit.org.uk</p>

    <p>Web: http://www.somakeit.org.uk/</p>
  </div>
  """

module.exports = class RegisterController extends Controller
  @before 'requireAdmin'
  @before 'loadRoles', only: ['settings']

  view: (done) ->
    @detailsHtml = @plugin.get('detailsHtml') ? defaultDetailsHtml
    @req.models.RoleUser.find()
    .where("role_id = ? AND approved IS NOT NULL AND rejected IS NULL", [@plugin.get('memberRoleId') ? 1])
    .run (err, roleUsers) =>
      userIds = []
      @roleUsers = []
      for roleUser in roleUsers when roleUser.user_id not in userIds
        @roleUsers.push roleUser
        userIds.push roleUser.user_id
      getUser = (roleUser, next) ->
        roleUser.getUser (err, user) ->
          roleUser.user = user
          next(err)
      @plugin.async.map @roleUsers, getUser, done

  settings: (done) ->
    @data.memberRoleId ?= @plugin.get('memberRoleId') ? 1
    @data.detailsHtml ?= @plugin.get('detailsHtml') ? defaultDetailsHtml

    if @req.method is 'POST'
      @data.memberRoleId = parseInt(@data.memberRoleId, 10)
      for role in @roles when role.id is @data.memberRoleId
        @plugin.set {memberRoleId: @data.memberRoleId}
        break
      @plugin.set {detailsHtml: @data.detailsHtml}
    done()

  requireAdmin: (done) ->
    unless @req.user and @req.user.can('admin')
      err = new Error "Permission denied"
      err.status = 403
      return done err
    else
      done()

  loadRoles: (done) ->
    @req.models.Role.find (err, @roles) =>
      done(err)
