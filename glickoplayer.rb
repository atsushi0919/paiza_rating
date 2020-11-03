# An class to Calculate Glicko rating
  # The class holds
  #   - @rating: glicko rating
  #   - @rd: rating deviation
  #   - @updated_at: the time when the rating is calculated.
  # Ref:
  #   http://www.glicko.net/glicko/glicko.pdf
  class GlickoPlayer
    attr_reader :rating, :rd, :updated_at

    Q = Math.log(10.0)/400.0

    def initialize(rating = 1500.0, rd = 350.0, updated_at = nil, c: 5.0, rd_min: 0.0, rd_max: 350.0)
      @rating = (rating || 1500.0).to_f
      @rd = (rd || 350).to_f
      @updated_at = updated_at
      @c = (c || 5.0).to_f
      @rd_min = (rd_min || 0.0).to_f
      @rd_max = (rd_max || 350.0).to_f
    end

    # Glicko Rating calculation STEP 1.
    # Update the rating based on the time.
    # For now, as "@c" is set to zero, the rating does not change.
    def update_time(now)
      t = @updated_at ? (now - @updated_at) : 0
      @rd = Math.sqrt(@rd**2 + @c**2 * t).clamp(@rd_min, @rd_max)
      @updated_at = now
    end

    # Glicko Rating calculation STEP 2
    # Update rating based on the fight.
    def fight(opponent, s)
      s = s.to_f
      opponent_rating = opponent.rating
      opponent_rd = opponent.rd
      g_opponent_rd = calc_g(opponent_rd)
      e = 1 / (1 + 10**(- g_opponent_rd * (rating - opponent_rating) / 400.0))
      d_squared_inv = Q**2 * g_opponent_rd**2 * e * (1 - e)
      rd_d_square = 1/ (1 / @rd**2 + d_squared_inv)
      rd_d_square = rd_d_square.clamp(@rd_min**2, @rd_max**2)
      @rating += Q * (rd_d_square) * g_opponent_rd * (s - e)
      # puts "rd: #{@rd} -> #{Math.sqrt(rd_d_square)}, d_squared_inv: #{d_squared_inv}"
      @rd = Math.sqrt(rd_d_square)
      # puts "rating=#{@rating} rd=#{@rd}, rd_d_square=#{rd_d_square}, rd_min=#{@rd_min}"

      # puts "g_opponent_rd=#{g_opponent_rd}, e=#{e}, d_squared_inv=#{d_squared_inv}, d=#{1/Math.sqrt(d_squared_inv)}, rd_d_square=#{rd_d_square}"
    end
    def to_s
      "rating: #{@rating}, rd: #{@rd}, updated_at: #{@updated_at}"
    end

    private

    # For "fight" method
    def calc_g(rd)
      1 / Math.sqrt(1 + 3 * Q**2 * rd**2 / Math::PI**2)
    end
  end


user1 = GlickoPlayer.new(1500, 350)
user2 = GlickoPlayer.new(1500, 350)

10.times{
print("[#{user1.rating}, #{user2.rating}, #{user1.rd}, #{user2.rd}], ")

old_user1 = user1.dup
old_user2 = user2.dup

user1.fight(old_user2, 1)
user2.fight(old_user1, 0)

# puts "1: #{user1}"
# puts "2: #{user2}"
}