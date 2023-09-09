# --
# Copyright (C) 202 mo-azfar,https://github.com/mo-azfar/OTRS-Znuny-Quick-Note
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::TicketZoom::TicketQuickNote;

use parent 'Kernel::Output::HTML::Base';

use strict;
use warnings;

use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
   	my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
	
    my %Ticket    = %{ $Param{Ticket} };
    my %AclAction = %{ $Param{AclAction} };
	
	# check permissions
    my $Access = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPermission(
        Type     => 'note',
        TicketID => $Ticket{TicketID},
        UserID   => $Self->{UserID}
    );

	# set display options
    $Param{WidgetTitle} = Translatable('Ticket Widget');

    if ( $Access ) 
	{
        $LayoutObject->Block(
            Name => 'SubmitQuickNote',
		);

        if ($Param{Config}->{QuickCloseEnabled})
        {
            $LayoutObject->Block(
                Name => 'QuickClose',
		    );
        }
	}

    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentTicketZoom/TicketQuickNote',
        Data         => { %Param, %Ticket, %AclAction },
    );
	
	return {
        Output => $Output,
    };
}

1;
